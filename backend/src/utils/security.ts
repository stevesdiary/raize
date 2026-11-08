import * as argon2 from 'argon2';
import * as crypto from 'crypto';
import { env } from '../config/env.js';

/**
 * Hash password using Argon2id with memory cost 64MB and 3 iterations
 */
export async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 2 ** 16, // 64 MB
    timeCost: 3,
    parallelism: 1,
  });
}

/**
 * Verify password against Argon2id hash
 */
export async function verifyPassword(hash: string, plain: string): Promise<boolean> {
  try {
    return await argon2.verify(hash, plain);
  } catch {
    return false;
  }
}

/**
 * Derive 256-bit symmetric encryption key using Argon2id Key Derivation Function (KDF)
 * Implements RFC 9106 Argon2id memory-hard key derivation.
 */
export async function deriveKeyWithArgon2(passphrase: string, salt: Buffer): Promise<Buffer> {
  return argon2.hash(passphrase, {
    type: argon2.argon2id,
    raw: true,
    hashLength: 32, // 256 bits for AES-256
    salt,
    memoryCost: 2 ** 16, // 64 MB memory cost
    timeCost: 3,
    parallelism: 1,
  });
}

/**
 * Argon2id-Derived AES-256-GCM Envelope Encryption for Sensitive Health Records
 * Format: v{version}:{salt_hex}:{iv_hex}:{tag_hex}:{ciphertext_hex}
 */
export async function encryptSensitiveField(plainText: string, keyVersion = 1): Promise<string> {
  const salt = crypto.randomBytes(16); // 128-bit salt for Argon2id
  const iv = crypto.randomBytes(12); // Standard 96-bit IV for AES-GCM
  const key = await deriveKeyWithArgon2(env.ENCRYPTION_KEY, salt);

  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  let encrypted = cipher.update(plainText, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const tag = cipher.getAuthTag().toString('hex');

  return `v${keyVersion}:${salt.toString('hex')}:${iv.toString('hex')}:${tag}:${encrypted}`;
}

/**
 * Argon2id-Derived AES-256-GCM Envelope Decryption
 */
export async function decryptSensitiveField(envelope: string): Promise<string> {
  if (!envelope || !envelope.startsWith('v')) return envelope;

  const parts = envelope.split(':');
  if (parts.length !== 5) return envelope;

  const [, saltHex, ivHex, tagHex, cipherHex] = parts;
  const salt = Buffer.from(saltHex, 'hex');
  const iv = Buffer.from(ivHex, 'hex');
  const tag = Buffer.from(tagHex, 'hex');

  const key = await deriveKeyWithArgon2(env.ENCRYPTION_KEY, salt);
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);

  let decrypted = decipher.update(cipherHex, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

/**
 * One-way SHA-256 hashing for IP addresses under NDPA 2023 data minimization
 */
export function hashSha256(data: string): string {
  return crypto.createHash('sha256').update(data).digest('hex');
}

/**
 * Verify Paystack HMAC-SHA512 Webhook Signature
 */
export function verifyPaystackSignature(payload: string, signature: string): boolean {
  const hash = crypto
    .createHmac('sha512', env.PAYSTACK_SECRET_KEY)
    .update(payload)
    .digest('hex');
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(signature));
}
