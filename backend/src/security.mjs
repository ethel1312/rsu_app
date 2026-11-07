import { createHash, createHmac, randomUUID, timingSafeEqual } from 'node:crypto';
import { SignJWT, jwtVerify } from 'jose';

export const TOKEN_TTL_SECONDS = 8 * 60 * 60;
export const JWT_ISSUER = 'urn:rsu:conductor-api';
export const JWT_AUDIENCE = 'urn:rsu:conductor-app';

export function secret() {
  const value = process.env.TOKEN_SECRET || '';
  if (value.length < 64) throw new Error('TOKEN_SECRET must contain at least 64 characters');
  return value;
}

export function signature(value) {
  return createHmac('sha256', secret()).update(value).digest('base64url');
}

function equal(a, b) {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  return left.length === right.length && timingSafeEqual(left, right);
}

export async function issueToken(employee, now = Date.now()) {
  const issuedAt = Math.floor(now / 1000);
  return new SignJWT({ version: signature(employee.password) })
    .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
    .setSubject(String(employee.id))
    .setIssuer(JWT_ISSUER)
    .setAudience(JWT_AUDIENCE)
    .setJti(randomUUID())
    .setIssuedAt(issuedAt)
    .setExpirationTime(issuedAt + TOKEN_TTL_SECONDS)
    .sign(new TextEncoder().encode(secret()));
}

export async function readToken(token, now = Date.now()) {
  try {
    const { payload } = await jwtVerify(token, new TextEncoder().encode(secret()), {
      algorithms: ['HS256'], typ: 'JWT', issuer: JWT_ISSUER, audience: JWT_AUDIENCE,
      requiredClaims: ['sub', 'iat', 'exp', 'jti', 'version'],
      maxTokenAge: TOKEN_TTL_SECONDS,
      currentDate: new Date(now),
    });
    if (!/^[1-9]\d*$/.test(payload.sub) || !Number.isSafeInteger(Number(payload.sub)) ||
        typeof payload.jti !== 'string' || !payload.jti || typeof payload.version !== 'string') return null;
    return payload;
  } catch { return null; }
}

export const tokenHash = (token) => createHash('sha256').update(token).digest('hex');

export async function verifyPassword(input, stored) {
  if (/^\$2[aby]\$/.test(stored)) {
    const { default: bcrypt } = await import('bcryptjs');
    return bcrypt.compare(input, stored.replace(/^\$2y\$/, '$2b$'));
  }
  // Compatibilidad con empleados históricos del administrador. Se migra al entrar.
  return equal(input, stored);
}

export async function hashPassword(value) {
  const { default: bcrypt } = await import('bcryptjs');
  return bcrypt.hash(value, 12);
}
