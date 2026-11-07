let pool;
export async function database() {
  if (!pool) {
    for (const key of ['DB_HOST', 'DB_DATABASE', 'DB_USERNAME', 'DB_PASSWORD']) {
      if (!process.env[key]) throw new Error(`Missing ${key}`);
    }
    const { default: mysql } = await import('mysql2/promise');
    pool = mysql.createPool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT || 4000),
      user: process.env.DB_USERNAME,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_DATABASE,
      ssl: { rejectUnauthorized: true, ...(process.env.DB_SSL_CA ? { ca: process.env.DB_SSL_CA.replaceAll('\\n', '\n') } : {}) },
      connectionLimit: 3,
      maxIdle: 1,
      idleTimeout: 10000,
      connectTimeout: 10000,
      dateStrings: true,
      timezone: 'Z',
      enableKeepAlive: true,
    });
  }
  return pool;
}
