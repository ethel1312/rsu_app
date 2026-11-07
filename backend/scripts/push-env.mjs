import { existsSync, readFileSync } from 'node:fs';
import { parseEnv } from 'node:util';
import { spawnSync } from 'node:child_process';

if (!existsSync('.vercel/project.json')) throw new Error('Primero ejecuta npx vercel link desde backend.');
if (!existsSync('.env.production')) throw new Error('Primero ejecuta node --env-file=.env scripts/provision.mjs.');
const config = parseEnv(readFileSync('.env.production', 'utf8'));
const required = ['DB_HOST', 'DB_PORT', 'DB_DATABASE', 'DB_USERNAME', 'DB_PASSWORD', 'TOKEN_SECRET'];
for (const key of required) {
  if (!config[key]) throw new Error(`Falta ${key} en .env.production.`);
}
if (config.DB_USERNAME.endsWith('.root') || config.DB_USERNAME === 'root') throw new Error('No se permite desplegar con el usuario root.');
if (config.TOKEN_SECRET.length < 64) throw new Error('TOKEN_SECRET debe tener al menos 64 caracteres.');
for (const key of [...required, 'DB_SSL_CA']) {
  if (!config[key]) continue;
  // Solo claves de la lista fija entran al comando; los valores privados van por stdin.
  const result = spawnSync(process.platform === 'win32' ? 'npx.cmd' : 'npx',
    ['--yes', 'vercel@latest', 'env', 'add', key, 'production', '--force', '--type', 'secret'], {
      shell: process.platform === 'win32',
      input: config[key], encoding: 'utf8', stdio: ['pipe', 'inherit', 'inherit'],
    });
  if (result.error || result.status !== 0) throw new Error(`No se pudo cargar ${key}. Revisa la sesión y el proyecto de Vercel.`);
}
console.log('Variables cargadas en Production. Ejecuta npx vercel --prod para aplicarlas.');
