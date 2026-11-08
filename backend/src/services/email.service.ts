import { SendByte, SendByteError } from '@sendbyte/node';
import { env } from '../config/env.js';

// Initialize SendByte client
const sendbyte = new SendByte(env.SENDBYTE_API_KEY);

export interface SendEmailOptions {
  to: string | string[];
  subject: string;
  html?: string;
  text?: string;
  idempotencyKey?: string;
}

/**
 * Core transactional email sender via SendByte (sendbyte.africa)
 */
export async function sendTransactionalEmail(options: SendEmailOptions) {
  // In development/test with mock key, log without throwing network errors
  if (env.NODE_ENV === 'test' || env.SENDBYTE_API_KEY.includes('mock')) {
    console.log(`[SendByte Mock] Dispatching email to ${options.to}: "${options.subject}"`);
    return { id: `mock_sb_msg_${Date.now()}`, status: 'queued' };
  }

  try {
    const response = await sendbyte.emails.send({
      from: env.SENDBYTE_FROM_EMAIL,
      to: options.to,
      subject: options.subject,
      html: options.html,
      text: options.text,
      idempotency_key: options.idempotencyKey,
    });

    return response;
  } catch (error) {
    if (error instanceof SendByteError) {
      console.error('[SendByte API Error]:', error.message);
    } else {
      console.error('[SendByte Unexpected Error]:', error);
    }
    throw error;
  }
}

/**
 * Welcome Email upon registration
 */
export async function sendWelcomeEmail(to: string, firstName: string) {
  const name = firstName || 'Athlete';
  const subject = 'Welcome to Raize — Your Fitness Journey Begins';
  const html = `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; color: #111827;">
      <h1 style="color: #6366F1; font-size: 26px; margin-bottom: 16px;">Welcome to Raize, ${name}!</h1>
      <p style="font-size: 16px; line-height: 1.6; color: #374151;">
        Thank you for joining the unified fitness platform. Raize connects your workouts, nutrition, and outdoor activities into a single continuous feedback system.
      </p>
      <div style="background-color: #F3F4F6; border-radius: 8px; padding: 20px; margin: 24px 0;">
        <h3 style="margin-top: 0; color: #1F2937;">Your Next Step</h3>
        <p style="margin-bottom: 0; font-size: 15px; color: #4B5563;">
          Complete your <strong>3-minute fitness assessment</strong> to establish your baseline and generate your personalized weekly training blueprint.
        </p>
      </div>
      <p style="font-size: 14px; color: #6B7280;">
        Stay consistent,<br/>
        <strong>The Raize Team</strong>
      </p>
    </div>
  `;

  return sendTransactionalEmail({
    to,
    subject,
    html,
    text: `Welcome to Raize, ${name}! Complete your 3-minute fitness assessment to receive your personalized training plan.`,
    idempotencyKey: `welcome-${to}`,
  });
}

/**
 * Password Reset Email
 */
export async function sendPasswordResetEmail(to: string, resetToken: string) {
  const resetUrl = `https://raize.fit/auth/reset-password?token=${encodeURIComponent(resetToken)}`;
  const subject = 'Reset Your Raize Account Password';
  const html = `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; color: #111827;">
      <h2 style="color: #111827; font-size: 22px;">Password Reset Request</h2>
      <p style="font-size: 15px; color: #4B5563; line-height: 1.6;">
        We received a request to reset the password for your Raize account. Click the button below to establish a new password:
      </p>
      <p style="margin: 24px 0;">
        <a href="${resetUrl}" style="background-color: #6366F1; color: #ffffff; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: 600; display: inline-block;">
          Reset Password
        </a>
      </p>
      <p style="font-size: 13px; color: #9CA3AF;">
        If you did not request this change, you can safely ignore this email. This link will expire in 60 minutes.
      </p>
    </div>
  `;

  return sendTransactionalEmail({
    to,
    subject,
    html,
    text: `Reset your Raize password by clicking this link: ${resetUrl}`,
  });
}

/**
 * Medical / Cardiac Safety Alert Email (Stage E E05 trigger)
 */
export async function sendCardiacSafetyAlertEmail(to: string, firstName: string) {
  const name = firstName || 'Athlete';
  const subject = 'URGENT: Raize Health & Safety Notification';
  const html = `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; color: #111827;">
      <h2 style="color: #EF4444; font-size: 22px; margin-bottom: 12px;">Important Safety Notice</h2>
      <p style="font-size: 15px; color: #374151; line-height: 1.6;">
        Hello ${name},
      </p>
      <p style="font-size: 15px; color: #374151; line-height: 1.6;">
        During your recent fitness screening, you noted symptoms of <strong>chest pain, fainting, or acute shortness of breath</strong> during physical activity.
      </p>
      <div style="background-color: #FEF2F2; border-left: 4px solid #EF4444; padding: 16px; margin: 20px 0;">
        <p style="margin: 0; font-size: 14px; color: #991B1B; font-weight: 500;">
          Your exercise plan generation has been paused for your safety. We strongly advise you to consult a qualified physician or healthcare provider for an exercise stress test and clearance before resuming strenuous training.
        </p>
      </div>
      <p style="font-size: 13px; color: #6B7280;">
        Your wellbeing is our highest priority. Once you obtain medical clearance, you may update your health profile in your app settings.
      </p>
    </div>
  `;

  return sendTransactionalEmail({
    to,
    subject,
    html,
    text: `URGENT: Exercise recommendations have been paused due to reported symptoms. Please seek professional medical evaluation.`,
  });
}

/**
 * Subscription Payment Receipt (Paystack)
 */
export async function sendPaymentReceiptEmail(
  to: string,
  firstName: string,
  planName: string,
  amountNgn: number,
  reference: string
) {
  const name = firstName || 'Athlete';
  const subject = `Payment Confirmed: ${planName}`;
  const html = `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; color: #111827;">
      <h2 style="color: #10B981; font-size: 22px;">Payment Receipt</h2>
      <p style="font-size: 15px; color: #374151;">
        Thank you for your subscription, ${name}! Your payment has been successfully processed.
      </p>
      <table style="width: 100%; border-collapse: collapse; margin: 20px 0; font-size: 14px;">
        <tr style="border-bottom: 1px solid #E5E7EB;">
          <td style="padding: 10px 0; color: #6B7280;">Plan</td>
          <td style="padding: 10px 0; font-weight: 600; text-align: right;">${planName}</td>
        </tr>
        <tr style="border-bottom: 1px solid #E5E7EB;">
          <td style="padding: 10px 0; color: #6B7280;">Amount Paid</td>
          <td style="padding: 10px 0; font-weight: 600; text-align: right;">₦${amountNgn.toLocaleString()}</td>
        </tr>
        <tr style="border-bottom: 1px solid #E5E7EB;">
          <td style="padding: 10px 0; color: #6B7280;">Transaction Ref</td>
          <td style="padding: 10px 0; font-family: monospace; text-align: right;">${reference}</td>
        </tr>
      </table>
      <p style="font-size: 13px; color: #9CA3AF;">
        This receipt complies with statutory accounting standards (CAMA 2020). Keep this record for your files.
      </p>
    </div>
  `;

  return sendTransactionalEmail({
    to,
    subject,
    html,
    text: `Payment of ₦${amountNgn} confirmed for ${planName}. Ref: ${reference}`,
    idempotencyKey: `receipt-${reference}`,
  });
}
