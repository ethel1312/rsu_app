import { SignJWT, decodeJwt } from 'jose';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { issueToken, readToken, signature, JWT_ISSUER, JWT_AUDIENCE } from '../src/security.mjs';
import { limaNow, runsOn, serviceDate } from '../src/schedules.mjs';
import { createHandler } from '../api/index.mjs';

process.env.TOKEN_SECRET = 'a'.repeat(64);
const employee = { id: 7, status: 1, employee_type: 'Conductor', password: '$2y$example' };
const schedule = { id: 1, driver_id: 7, start_date: '2026-11-01', end_date: '2026-11-30',
  days_of_week: '[1,2,3,4,5]', excluded_dates: '["2026-11-09"]', status: 'Programada' };

test('firma, expiración y manipulación de sesión', async () => {
  const token = await issueToken(employee, 1000000);
  assert.equal((await readToken(token, 1000001)).sub, '7');
  assert.equal(await readToken(token, 1000000 + 28800001), null);
  assert.equal(await readToken(token + 'a', 1000001), null);
  assert.equal(await readToken('malformed'), null);
});

test('programación respeta días, exclusiones, finalización y fecha de Lima', () => {
  assert.equal(limaNow(new Date('2026-11-08T02:00:00Z')).date, '2026-11-07');
  assert.equal(runsOn(schedule, '2026-11-07'), false);
  assert.equal(runsOn(schedule, '2026-11-09'), false);
  assert.equal(serviceDate(schedule, '2026-11-07'), '2026-11-10');
  assert.equal(serviceDate({ ...schedule, status: 'Finalizada' }, '2026-11-07'), null);
});

async function request(db, url, token = null, method = 'GET', body) {
  token ??= await issueToken(employee);
  let result;
  const response = { setHeader() {}, end(raw) { result = JSON.parse(raw); } };
  await createHandler(async () => db)({ url, method, body, headers: { authorization: `Bearer ${token}` } }, response);
  return { status: response.statusCode, body: result };
}

test('sin sesión no consulta datos del conductor', async () => {
  const db = { execute() { assert.fail('No debe consultar'); } };
  assert.equal((await request(db, '/api/schedules', 'invalid')).status, 401);
});

test('rechaza ayudantes e inactivos aunque tengan una sesión firmada', async () => {
  for (const fields of [{ employee_type: 'Ayudante' }, { status: 0 }]) {
    const db = { async execute() { return [[{ ...employee, ...fields }]]; } };
    assert.equal((await request(db, '/api/schedules')).status, 401);
  }
});

test('cambiar la contraseña invalida las sesiones anteriores', async () => {
  const db = { async execute() { return [[{ ...employee, password: 'changed' }]]; } };
  assert.equal((await request(db, '/api/schedules')).status, 401);
});

test('detalle ajeno usa filtro por conductor y devuelve 404', async () => {
  const db = { async execute(sql, params) {
    if (sql.includes('employee_types')) return [[employee]];
    assert.ok(sql.includes('WHERE id = ? AND driver_id = ?'));
    assert.deepEqual(params, ['999', 7]);
    return [[]];
  } };
  assert.equal((await request(db, '/api/schedules/999?date=2026-11-10')).status, 404);
});

test('listado consulta únicamente las programaciones del conductor autenticado', async () => {
  const db = { async execute(sql, params) {
    if (sql.includes('employee_types')) return [[employee]];
    assert.ok(sql.includes('p.driver_id = ?'));
    assert.equal(params[0], 7);
    return [[]];
  } };
  const result = await request(db, '/api/schedules');
  assert.equal(result.status, 200);
  assert.deepEqual(result.body.schedules, []);
});

test('inicio ajeno revierte la transacción sin escribir', async () => {
  const events = [];
  const connection = {
    async beginTransaction() { events.push('begin'); },
    async rollback() { events.push('rollback'); },
    release() { events.push('release'); },
    async execute(sql, params) {
      assert.ok(!sql.includes('INSERT'));
      if (sql.includes('FROM shifts')) return [[]];
      assert.deepEqual(params, ['999', 7]);
      return [[]];
    },
  };
  const db = { async execute() { return [[employee]]; }, async getConnection() { return connection; } };
  const result = await request(db, '/api/schedules/999/start', await issueToken(employee), 'POST', { date: '2026-11-07' });
  assert.equal(result.status, 404);
  assert.deepEqual(events, ['begin', 'rollback', 'release']);
});

for (const scenario of [
  { name: 'rechaza inicio sin asistencia completa', present: false, run: false, status: 422, inserts: 0 },
  { name: 'rechaza segundo inicio del mismo servicio', present: true, run: true, status: 422, inserts: 0 },
  { name: 'confirma inicio con asistencia completa', present: true, run: false, status: 200, inserts: 1 },
]) {
  test(scenario.name, async () => {
    const today = limaNow().date;
    let inserts = 0;
    const events = [];
    const connection = {
      async beginTransaction() { events.push('begin'); },
      async commit() { events.push('commit'); },
      async rollback() { events.push('rollback'); },
      release() { events.push('release'); },
      async execute(sql) {
        if (sql.includes('FROM shifts')) { events.push('shared-lock'); return [[]]; }
        if (sql.includes('FROM programming_schedules')) {
          assert.ok(events.includes('shared-lock'));
          return [[{ ...schedule, start_date: today, end_date: today, days_of_week: '[1,2,3,4,5,6,7]',
            helper_ids: '[8]', helper_names: '["Ayudante"]', driver_name: 'Conductor', vehicle_id: 3,
            zone_name: 'Centro', vehicle_label: 'Camión', shift_name: 'Mañana', shift_start_time: '06:00:00', shift_end_time: '14:00:00' }]];
        }
        if (sql.includes('FROM attendances')) return [[{ employee_id: 7 }, ...(scenario.present ? [{ employee_id: 8 }] : [])]];
        if (sql.includes('FROM employees')) return [[{ id: 7, first_name: 'Conductor', last_name: 'Uno' }, { id: 8, first_name: 'Ayudante', last_name: 'Dos' }]];
        if (sql.includes('FROM vehicles')) return [[{ plate: 'ABC-123' }]];
        if (sql.includes('FROM schedule_runs')) return [scenario.run ? [{ started_at: '2026-11-07 12:00:00' }] : []];
        if (sql.includes('INSERT INTO schedule_runs')) { inserts++; return [{ affectedRows: 1 }]; }
        assert.fail(sql);
      },
    };
    const db = { async execute() { return [[employee]]; }, async getConnection() { return connection; } };
    const result = await request(db, '/api/schedules/1/start', await issueToken(employee), 'POST', { date: today });
    assert.equal(result.status, scenario.status);
    assert.equal(inserts, scenario.inserts);
    assert.ok(events.includes(scenario.status === 200 ? 'commit' : 'rollback'));
    if (scenario.status === 200) assert.equal(result.body.started, true);
  });
}

test('login limita intentos con contador persistente antes de verificar contraseñas', async () => {
  const calls = [];
  const db = { async execute(sql) {
    calls.push(sql);
    if (sql.startsWith('INSERT') || sql.startsWith('DELETE')) return [{ affectedRows: 1 }];
    return [[{ attempts: 11 }]];
  } };
  const result = await request(db, '/api/login', '', 'POST', { username: '12345678', password: 'secret' });
  assert.equal(result.status, 429);
  assert.equal(calls.length, 3);
});


test('JWT tiene formato estándar y no expone la contraseña', async () => {
  const token = await issueToken(employee);
  assert.equal(token.split('.').length, 3);
  const claims = decodeJwt(token);
  assert.equal(claims.iss, JWT_ISSUER);
  assert.equal(claims.aud, JWT_AUDIENCE);
  assert.equal(claims.sub, '7');
  assert.equal(claims.exp - claims.iat, 28800);
  assert.equal(claims.password, undefined);
  assert.ok(claims.jti);
});

for (const scenario of [
  { name: 'otro emisor', issuer: 'urn:other', audience: JWT_AUDIENCE, alg: 'HS256' },
  { name: 'otro destinatario', issuer: JWT_ISSUER, audience: 'urn:other', alg: 'HS256' },
  { name: 'algoritmo no permitido', issuer: JWT_ISSUER, audience: JWT_AUDIENCE, alg: 'HS384' },
]) {
  test(`JWT rechaza ${scenario.name}`, async () => {
    const token = await new SignJWT({ version: signature(employee.password) })
      .setProtectedHeader({ alg: scenario.alg, typ: 'JWT' })
      .setSubject('7').setIssuer(scenario.issuer).setAudience(scenario.audience)
      .setJti('test').setIssuedAt().setExpirationTime('1h')
      .sign(new TextEncoder().encode(process.env.TOKEN_SECRET));
    assert.equal(await readToken(token), null);
  });
}

test('JWT rechaza fechas de emisión futuras y tokens antiguos de formato propio', async () => {
  assert.equal(await readToken(await issueToken(employee, Date.now() + 60000)), null);
  const payload = Buffer.from(JSON.stringify({ sub: 7, exp: 9999999999 })).toString('base64url');
  assert.equal(await readToken(`${payload}.${signature(payload)}`), null);
});

test('sesión eliminada del servidor rechaza un JWT todavía vigente', async () => {
  const db = { async execute(sql, params) {
    assert.ok(sql.includes('JOIN mobile_sessions'));
    assert.ok(sql.includes('s.expires_at > UTC_TIMESTAMP()'));
    assert.equal(params[0], 7);
    assert.match(params[1], /^[a-f0-9]{64}$/);
    return [[]];
  } };
  assert.equal((await request(db, '/api/schedules')).status, 401);
});

test('logout elimina únicamente la sesión del JWT presentado', async () => {
  let deleted = false;
  const db = { async execute(sql, params) {
    if (sql.includes('employee_types')) return [[employee]];
    assert.ok(sql.includes('DELETE FROM mobile_sessions WHERE token_hash = ? AND employee_id = ?'));
    assert.match(params[0], /^[a-f0-9]{64}$/);
    assert.equal(params[1], 7);
    deleted = true;
    return [{ affectedRows: 1 }];
  } };
  assert.equal((await request(db, '/api/logout', null, 'POST')).status, 200);
  assert.equal(deleted, true);
});
