import { describe, it, expect } from 'vitest';
import {
  hashPassword,
  verifyPassword,
  deriveKeyWithArgon2,
  encryptSensitiveField,
  decryptSensitiveField,
} from '../utils/security.js';
import * as crypto from 'crypto';

describe('Argon2 Security, Password Hashing & Key Derivation (RFC 9106)', () => {
  it('hashes passwords with Argon2id and verifies successfully', async () => {
    const password = 'SuperSecretFitnessPassword2026!';
    const hash = await hashPassword(password);

    expect(hash).toContain('$argon2id$');
    expect(await verifyPassword(hash, password)).toBe(true);
    expect(await verifyPassword(hash, 'WrongPassword123')).toBe(false);
  });

  it('derives high-entropy 256-bit symmetric key using Argon2id KDF', async () => {
    const salt = crypto.randomBytes(16);
    const key = await deriveKeyWithArgon2('master_passphrase', salt);

    expect(key).toBeInstanceOf(Buffer);
    expect(key.length).toBe(32); // 256 bits for AES-256
  });

  it('encrypts and decrypts sensitive health fields using Argon2id-derived AES-256-GCM', async () => {
    const confidentialClinicalNote = 'Patient experiences mild thoracic tension after high-volume bench pressing.';
    const envelope = await encryptSensitiveField(confidentialClinicalNote, 1);

    expect(envelope).toMatch(/^v1:[0-9a-f]{32}:[0-9a-f]{24}:[0-9a-f]{32}:[0-9a-f]+$/);

    const decrypted = await decryptSensitiveField(envelope);
    expect(decrypted).toBe(confidentialClinicalNote);
  });
});

