// Ejecutar una vez desde backend con las credenciales administrativas en .env.
// El despliegue recibe un usuario propio con permisos limitados, nunca el usuario root.
import { randomBytes } from 'node:crypto';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { database } from '../src/db.mjs';

const db = await database();
try {
  for (const statement of readFileSync(new URL('./setup.sql', import.meta.url), 'utf8').split(/;\s*(?:\r?\n|$)/u).filter(value => value.trim())) {
    await db.query(statement);
  }
  const { parseEnv } = await import('node:util');
  const existing = existsSync('.env.production') ? parseEnv(readFileSync('.env.production', 'utf8')) : null;
  const user = existing?.DB_USERNAME || `rsu_mobile_${randomBytes(4).toString('hex')}`;
  const password = existing?.DB_PASSWORD || randomBytes(32).toString('base64url');
  const { default: mysql } = await import('mysql2/promise');
  const account = `${mysql.escape(user)}@'%'`;
  const schema = mysql.escapeId(process.env.DB_DATABASE);
  if (!existing) await db.query(`CREATE USER ${account} IDENTIFIED BY ${mysql.escape(password)}`);
  for (const table of ['employees', 'employee_types', 'programming_schedules', 'vehicles', 'attendances', 'schedule_runs', 'shifts']) {
    await db.query(`GRANT SELECT ON ${schema}.${mysql.escapeId(table)} TO ${account}`);
  }
  await db.query(`GRANT UPDATE (password) ON ${schema}.employees TO ${account}`);
  await db.query(`GRANT INSERT ON ${schema}.schedule_runs TO ${account}`);
  await db.query(`GRANT SELECT, INSERT, UPDATE, DELETE ON ${schema}.mobile_login_attempts TO ${account}`);
  await db.query(`GRANT SELECT, INSERT, DELETE ON ${schema}.mobile_sessions TO ${account}`);
  const config = {
    DB_HOST: process.env.DB_HOST, DB_PORT: process.env.DB_PORT || '4000',
    DB_DATABASE: process.env.DB_DATABASE, DB_USERNAME: user, DB_PASSWORD: password,
    TOKEN_SECRET: existing?.TOKEN_SECRET || randomBytes(32).toString('hex'),
    ...(process.env.DB_SSL_CA ? { DB_SSL_CA: process.env.DB_SSL_CA } : {}),
  };
  writeFileSync('.env.production', Object.entries(config).map(([key, value]) => `${key}=${JSON.stringify(value)}`).join('\n') + '\n', { mode: 0o600 });
  console.log('Tablas móviles y permisos preparados. Configuración privada en .env.production.');
} finally { await db.end(); }
