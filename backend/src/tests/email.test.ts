import { describe, it, expect } from 'vitest';
import {
  sendTransactionalEmail,
  sendWelcomeEmail,
  sendPasswordResetEmail,
  sendCardiacSafetyAlertEmail,
  sendPaymentReceiptEmail,
} from '../services/email.service.js';

describe('SendByte Email Service Integration (@sendbyte/node)', () => {
  it('dispatches transactional email via SendByte with idempotency key', async () => {
    const res = await sendTransactionalEmail({
      to: 'athlete@example.com',
      subject: 'Test Notification',
      text: 'Testing SendByte transactional delivery',
      idempotencyKey: 'test-idemp-key-001',
    });

    expect(res).toBeDefined();
    expect(res.status).toBe('queued');
  });

  it('formats and sends welcome email upon onboarding', async () => {
    const res = await sendWelcomeEmail('newuser@example.com', 'Amaka');
    expect(res).toBeDefined();
    expect(res.id).toBeDefined();
  });

  it('formats and sends password reset email with secure link', async () => {
    const res = await sendPasswordResetEmail('forgot@example.com', 'sample_reset_token_xyz');
    expect(res).toBeDefined();
    expect(res.id).toBeDefined();
  });

  it('dispatches urgent cardiac safety warning email for Stage E E05 trigger', async () => {
    const res = await sendCardiacSafetyAlertEmail('cardiac_alert@example.com', 'Tunde');
    expect(res).toBeDefined();
    expect(res.id).toBeDefined();
  });

  it('generates statutory CAMA 2020 receipt email for Paystack transactions', async () => {
    const res = await sendPaymentReceiptEmail(
      'paying_athlete@example.com',
      'Emeka',
      'Raize Premium (Monthly)',
      5000,
      'rz_tx_123456789'
    );
    expect(res).toBeDefined();
    expect(res.id).toBeDefined();
  });
});

