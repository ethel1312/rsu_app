import { database } from '../src/db.mjs';
const db = await database();
try {
  const [[tls]] = await db.query("SHOW STATUS LIKE 'Ssl_cipher'");
  if (!tls.Value) throw new Error('TLS no está activo');
  for (const table of ['employees', 'employee_types', 'programming_schedules', 'vehicles', 'attendances', 'schedule_runs', 'mobile_login_attempts', 'mobile_sessions']) {
    const [[row]] = await db.query(`SELECT COUNT(*) AS total FROM \`${table}\``);
    console.log(`${table}: ${row.total}`);
  }
  console.log('TiDB verificado con TLS.');
} finally { await db.end(); }
