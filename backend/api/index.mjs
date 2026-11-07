import { database } from '../src/db.mjs';
import { hashPassword, issueToken, readToken, signature, tokenHash, verifyPassword } from '../src/security.mjs';
import { jsonArray, limaNow, publicSchedule, runsOn, serviceDate } from '../src/schedules.mjs';

class ApiError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
const fail = (status, message) => { throw new ApiError(status, message); };
const driverQuery = `SELECT e.*, t.name AS employee_type FROM employees e
  JOIN employee_types t ON t.id = e.employee_type_id
  JOIN mobile_sessions s ON s.employee_id = e.id
  WHERE e.id = ? AND s.token_hash = ? AND s.expires_at > UTC_TIMESTAMP()`;
const isDriver = e => e && Number(e.status) === 1 && e.employee_type.toLowerCase() === 'conductor';
const profile = e => ({ id: e.id, name: `${e.first_name} ${e.last_name}`.trim(), dni: e.dni });

async function body(req) {
  if (req.body) {
    if (Buffer.byteLength(JSON.stringify(req.body)) > 4096) fail(413, 'Solicitud demasiado grande.');
    try { return typeof req.body === 'string' ? JSON.parse(req.body) : req.body; }
    catch { fail(400, 'Solicitud inválida.'); }
  }
  let raw = '';
  for await (const chunk of req) {
    raw += chunk;
    if (Buffer.byteLength(raw) > 4096) fail(413, 'Solicitud demasiado grande.');
  }
  try { return JSON.parse(raw || '{}'); } catch { fail(400, 'Solicitud inválida.'); }
}

async function authenticate(req, db) {
  const rawToken = (req.headers.authorization || '').replace(/^Bearer /, '');
  const token = await readToken(rawToken);
  if (!token) fail(401, 'Tu sesión venció. Vuelve a ingresar.');
  const [[employee]] = await db.execute(driverQuery, [Number(token.sub), tokenHash(rawToken)]);
  if (!isDriver(employee) || signature(employee.password) !== token.version) fail(401, 'Vuelve a iniciar sesión.');
  return employee;
}

async function login(req, db) {
  const data = await body(req);
  if (typeof data.username !== 'string' || typeof data.password !== 'string' ||
      data.username.length > 100 || !data.username.trim() || !data.password || Buffer.byteLength(data.password) > 72) {
    fail(422, 'Ingresa tu DNI o correo y una contraseña válida (máximo 72 bytes).');
  }
  // Límite persistente compartido por todas las instancias serverless; no depende de la memoria del proceso.
  const key = signature(data.username.trim().toLowerCase());
  await db.execute('DELETE FROM mobile_login_attempts WHERE window_start < UTC_TIMESTAMP() - INTERVAL 1 DAY LIMIT 100');
  await db.execute(`INSERT INTO mobile_login_attempts (attempt_key, attempts, window_start)
    VALUES (?, 1, UTC_TIMESTAMP()) ON DUPLICATE KEY UPDATE
    attempts = IF(window_start < UTC_TIMESTAMP() - INTERVAL 15 MINUTE, 1, attempts + 1),
    window_start = IF(window_start < UTC_TIMESTAMP() - INTERVAL 15 MINUTE, UTC_TIMESTAMP(), window_start)`, [key]);
  const [[attempt]] = await db.execute('SELECT attempts FROM mobile_login_attempts WHERE attempt_key = ?', [key]);
  if (attempt.attempts > 10) fail(429, 'Demasiados intentos. Intenta nuevamente en 15 minutos.');
  const [[employee]] = await db.execute(`SELECT e.*, t.name AS employee_type FROM employees e
    JOIN employee_types t ON t.id = e.employee_type_id WHERE e.dni = ? OR e.email = ? LIMIT 1`, [data.username.trim(), data.username.trim()]);
  if (!isDriver(employee) || !await verifyPassword(data.password, employee.password)) {
    fail(401, 'Credenciales incorrectas o conductor inactivo.');
  }
  if (!/^\$2[aby]\$/.test(employee.password)) {
    const hashed = await hashPassword(data.password);
    const [updated] = await db.execute('UPDATE employees SET password = ? WHERE id = ? AND password = ?', [hashed, employee.id, employee.password]);
    if (!updated.affectedRows) fail(409, 'Los datos cambiaron. Vuelve a ingresar.');
    employee.password = hashed;
  }
  await db.execute('DELETE FROM mobile_login_attempts WHERE attempt_key = ?', [key]);
  await db.execute('DELETE FROM mobile_sessions WHERE expires_at <= UTC_TIMESTAMP() LIMIT 100');
  const token = await issueToken(employee);
  const claims = await readToken(token);
  await db.execute(`INSERT INTO mobile_sessions (token_hash, employee_id, expires_at, created_at)
    VALUES (?, ?, ?, UTC_TIMESTAMP())`, [tokenHash(token), employee.id, new Date(claims.exp * 1000).toISOString().slice(0, 19).replace('T', ' ')]);
  return { token, token_type: 'Bearer', expires_in: claims.exp - claims.iat, driver: profile(employee) };
}

async function ownedSchedule(db, id, employee, lock = false) {
  const [[schedule]] = await db.execute(`SELECT * FROM programming_schedules WHERE id = ? AND driver_id = ?${lock ? ' FOR UPDATE' : ''}`, [id, employee.id]);
  if (!schedule) fail(404, 'No se encontró esta programación.');
  return schedule;
}

async function detail(db, schedule, date) {
  const now = limaNow();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date || '') || !runsOn(schedule, date)) fail(422, 'La programación no corresponde a esta fecha.');
  const ids = [Number(schedule.driver_id), ...jsonArray(schedule.helper_ids).map(Number)];
  const [records] = await db.execute(`SELECT employee_id FROM attendances WHERE employee_id IN (${ids.map(() => '?').join(',')})
    AND date = ? AND status = 'present' AND type = 'entry'${date === now.date ? ' AND time <= ?' : ''}`,
    [...ids, date, ...(date === now.date ? [now.time] : [])]);
  const present = new Set(records.map(row => Number(row.employee_id)));
  const [employees] = await db.execute(`SELECT id, first_name, last_name FROM employees WHERE id IN (${ids.map(() => '?').join(',')})`, ids);
  const names = new Map(employees.map(e => [Number(e.id), `${e.first_name} ${e.last_name}`.trim()]));
  const [[vehicle]] = await db.execute('SELECT plate FROM vehicles WHERE id = ?', [schedule.vehicle_id]);
  const [[run]] = await db.execute('SELECT started_at FROM schedule_runs WHERE programming_schedule_id = ? AND service_date = ?', [schedule.id, date]);
  const helpers = jsonArray(schedule.helper_names);
  const staff = ids.map((id, index) => ({ id, name: names.get(id) || (index === 0 ? schedule.driver_name : helpers[index - 1]) || 'Personal',
    role: index === 0 ? 'Conductor (Tú)' : 'Ayudante', present: present.has(id) }));
  return { ...publicSchedule(schedule, date, vehicle?.plate || ''), staff, started: Boolean(run?.started_at),
    can_start: date === now.date && staff.every(e => e.present) && !run };
}

export function createHandler(dbFactory = database) {
return async function handler(req, res) {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  try {
    const url = new URL(req.url, 'https://api.invalid');
    const path = (url.searchParams.has('route') ? `/api/${url.searchParams.get('route')}` : url.pathname).replace(/\/$/, '');
    const db = await dbFactory();
    let result;
    if (path === '/api/health' && req.method === 'GET') {
      await db.execute('SELECT 1');
      result = { status: 'ok' };
    } else if (path === '/api/login' && req.method === 'POST') {
      result = await login(req, db);
    } else {
      const employee = await authenticate(req, db);
      if (path === '/api/logout' && req.method === 'POST') {
        const rawToken = req.headers.authorization.replace(/^Bearer /, '');
        await db.execute('DELETE FROM mobile_sessions WHERE token_hash = ? AND employee_id = ?', [tokenHash(rawToken), employee.id]);
        result = { message: 'Sesión cerrada.' };
      } else if (path === '/api/schedules' && req.method === 'GET') {
        const today = limaNow().date;
        const [rows] = await db.execute(`SELECT p.*, v.plate FROM programming_schedules p
          LEFT JOIN vehicles v ON v.id = p.vehicle_id
          WHERE p.driver_id = ? AND p.status != 'Finalizada' AND p.end_date >= ? ORDER BY p.start_date, p.id`, [employee.id, today]);
        result = { driver: profile(employee), schedules: rows.flatMap(row => {
          const date = serviceDate(row, today);
          return date ? [publicSchedule(row, date, row.plate || '')] : [];
        }) };
      } else {
        const match = path.match(/^\/api\/schedules\/(\d+)(\/start)?$/);
        if (!match) fail(404, 'Recurso no encontrado.');
        if (!match[2] && req.method === 'GET') {
          result = await detail(db, await ownedSchedule(db, match[1], employee), url.searchParams.get('date'));
        } else if (match[2] && req.method === 'POST') {
          const data = await body(req);
          const connection = await db.getConnection();
          try {
            await connection.beginTransaction();
            // El administrador usa este mismo bloqueo al cambiar programaciones.
            await connection.execute('SELECT id FROM shifts ORDER BY id FOR UPDATE');
            const schedule = await ownedSchedule(connection, match[1], employee, true);
            const info = await detail(connection, schedule, data.date);
            if (!info.can_start) fail(422, info.started ? 'El recorrido ya fue iniciado.' : 'Solo puedes iniciar hoy y con toda la asistencia registrada.');
            await connection.execute(`INSERT INTO schedule_runs (programming_schedule_id, service_date, started_at, created_at, updated_at)
              VALUES (?, ?, UTC_TIMESTAMP(), UTC_TIMESTAMP(), UTC_TIMESTAMP())`, [schedule.id, data.date]);
            await connection.commit();
            result = { ...info, started: true, can_start: false };
          } catch (error) { await connection.rollback(); throw error; }
          finally { connection.release(); }
        } else fail(405, 'Método no permitido.');
      }
    }
    res.statusCode = 200;
    res.end(JSON.stringify(result));
  } catch (error) {
    if (!(error instanceof ApiError)) console.error('API failure', error.code || error.name);
    res.statusCode = error.status || 503;
    res.end(JSON.stringify({ message: error.status ? error.message : 'No se pudo conectar al servicio. Intenta nuevamente.' }));
  }
};
}

export default createHandler();
