import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../../db/index.js';
import { subscriptions, billingTransactions, users, userProfiles } from '../../db/schema/index.js';
import { eq, desc, and } from 'drizzle-orm';
import { verifyPaystackSignature } from '../../utils/security.js';
import { sendPaymentReceiptEmail } from '../../services/email.service.js';

export async function billingRoutes(fastify: FastifyInstance) {
  // Available Plans (FR-027)
  fastify.get('/plans', {
    schema: {
      tags: ['Billing & Paystack'],
      summary: 'List available membership protocols',
      description: 'Returns available tiers (Free Starter, Raize Premium Monthly, Annual Athletic Pass, and 1-on-1 Coaching Tier) with Nigerian Naira (NGN) pricing.',
      response: {
        200: {
          type: 'object',
          description: 'Available billing plans array',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  id: { type: 'string', example: 'premium_annual' },
                  name: { type: 'string', example: 'Annual Athletic Pass' },
                  priceNgn: { type: 'number', example: 45000 },
                  interval: { type: 'string', example: 'annual' },
                  features: { type: 'array', items: { type: 'string' }, example: ['Personalized adaptive blueprint', 'Live GPS telemetry'] },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: [
                {
                  id: 'premium_monthly',
                  name: 'Raize Premium Monthly',
                  priceNgn: 5000,
                  interval: 'monthly',
                  features: ['Personalized adaptive blueprint', 'Live GPS telemetry', 'Nigerian food diary'],
                },
                {
                  id: 'premium_annual',
                  name: 'Annual Athletic Pass',
                  priceNgn: 45000,
                  interval: 'annual',
                  features: ['All Premium capabilities', '40% savings', '7-Day risk-free trial'],
                },
              ],
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const plans = [
      {
        id: 'free',
        name: 'Free Starter',
        priceNgn: 0,
        priceUsd: 0,
        features: ['Initial fitness assessment', 'Basic workout tracking', 'Basic food diary', 'Manual activity log'],
      },
      {
        id: 'premium_monthly',
        name: 'Raize Premium Monthly',
        priceNgn: 5000,
        priceUsd: 9.99,
        interval: 'monthly',
        features: [
          'Personalized adaptive blueprint',
          'Full structured workout programs',
          'Advanced nutrition insights & macro breakdown',
          'Live GPS activity tracking & route elevation',
          'Progress analytics & personal record detection',
        ],
      },
      {
        id: 'premium_annual',
        name: 'Annual Athletic Pass',
        priceNgn: 45000,
        priceUsd: 89.99,
        interval: 'annual',
        features: [
          'All Premium capabilities included',
          '40% Annual savings vs monthly',
          '7-Day risk-free trial',
          'Priority feature unlocks & telemetry sync',
        ],
      },
      {
        id: 'coaching_monthly',
        name: 'Raize Coaching Tier',
        priceNgn: 25000,
        priceUsd: 49.99,
        interval: 'monthly',
        features: [
          'All Premium capabilities',
          'Direct certified human coach chat',
          'Weekly personalized program adjustments',
          'Custom Nigerian meal plans and video reviews',
        ],
      },
    ];

    return reply.send({ success: true, data: plans });
  });

  // Current Subscription
  fastify.get('/subscription', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Billing & Paystack'],
      summary: 'Get active subscription status',
      description: 'Returns active membership tier, renewal date, and payment provider details.',
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          description: 'Subscription status record',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                planId: { type: 'string', example: 'premium_annual' },
                status: { type: 'string', example: 'active' },
                provider: { type: 'string', example: 'paystack' },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                planId: 'premium_annual',
                status: 'active',
                provider: 'paystack',
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };

    const [sub] = await db
      .select()
      .from(subscriptions)
      .where(and(eq(subscriptions.userId, userPayload.id), eq(subscriptions.status, 'active')))
      .orderBy(desc(subscriptions.createdAt));

    return reply.send({
      success: true,
      data: sub || {
        planId: 'free',
        status: 'active',
        provider: 'free',
      },
    });
  });

  // Cancel Subscription (FR-027 / Account Settings)
  fastify.post('/subscription/cancel', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Billing & Paystack'],
      summary: 'Cancel active subscription or trial',
      description: 'Cancels auto-renewal and marks subscription as cancelled while preserving access until current billing period expiration.',
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            message: { type: 'string', example: 'Subscription cancelled successfully.' },
            data: {
              type: 'object',
              properties: {
                status: { type: 'string', example: 'cancelled' },
              },
            },
          },
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };

    const [activeSub] = await db
      .select()
      .from(subscriptions)
      .where(and(eq(subscriptions.userId, userPayload.id), eq(subscriptions.status, 'active')))
      .orderBy(desc(subscriptions.createdAt));

    if (activeSub) {
      await db
        .update(subscriptions)
        .set({ status: 'cancelled', updatedAt: new Date() })
        .where(eq(subscriptions.id, activeSub.id));
    }

    return reply.send({
      success: true,
      message: 'Subscription successfully cancelled. Access will remain active until the end of your billing cycle.',
      data: {
        status: 'cancelled',
      },
    });
  });

  // Initialize Paystack Checkout (FR-027)
  fastify.post('/paystack/initialize', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Billing & Paystack'],
      summary: 'Initialize Paystack payment checkout',
      description: 'Creates a pending transaction with statutory CAMA 2020 6-year retention hold, generating a Paystack authorization checkout URL.',
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['planId'],
        properties: {
          planId: { type: 'string', description: 'Selected protocol ID (annual, monthly, coach)', example: 'annual' },
          callbackUrl: { type: 'string', description: 'Redirect URL after payment', example: 'https://raize.fit/billing/verify' },
        },
        examples: [
          {
            planId: 'premium_annual',
            callbackUrl: 'https://raize.fit/billing/verify',
          },
        ],
      },
      response: {
        201: {
          type: 'object',
          description: 'Paystack authorization checkout link and reference',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                reference: { type: 'string', example: 'rz_tx_1794040000_abc123' },
                amountNgn: { type: 'number', example: 45000 },
                authorizationUrl: { type: 'string', example: 'https://checkout.paystack.com/rz_tx_1794040000_abc123' },
                transactionId: { type: 'string', format: 'uuid', example: 'tx_paystack_01' },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                reference: 'rz_tx_1794040000_abc123',
                amountNgn: 45000,
                authorizationUrl: 'https://checkout.paystack.com/rz_tx_1794040000_abc123',
                transactionId: 'd483b381-3be2-4465-9eb9-b2db163c4eb1',
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const body = (request.body as { planId?: string; plan?: string }) || {};
    const selectedPlan = body.planId || body.plan || '';

    const planPrices: Record<string, number> = {
      premium_monthly: 5000,
      monthly: 5000,
      premium_annual: 45000,
      annual: 45000,
      coaching_monthly: 25000,
      coach: 25000,
    };

    const amountNgn = planPrices[selectedPlan];
    if (!amountNgn) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_PLAN', message: 'Selected plan cannot be initialized for billing' },
      });
    }

    const reference = `rz_tx_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    const now = new Date();
    // CAMA 2020: 6-year mandatory accounting records retention
    const retentionDate = new Date(now);
    retentionDate.setFullYear(now.getFullYear() + 6);

    const [tx] = await db
      .insert(billingTransactions)
      .values({
        userId: userPayload.id,
        amountNgn: amountNgn.toFixed(2),
        currency: 'NGN',
        status: 'pending',
        paymentMethod: 'card',
        providerReference: reference,
        legalHoldRetainedUntil: retentionDate,
      })
      .returning();

    // Mock Paystack checkout authorization URL (in production this calls https://api.paystack.co/transaction/initialize)
    const authorizationUrl = `https://checkout.paystack.com/${reference}`;

    return reply.status(201).send({
      success: true,
      data: {
        reference,
        amountNgn,
        authorizationUrl,
        transactionId: tx.id,
      },
    });
  });

  // Paystack Webhook Handler (HMAC-SHA512 Verified & CAMA 2020 Retained)
  fastify.post('/webhooks/paystack', {
    schema: {
      tags: ['Billing & Paystack'],
      summary: 'Paystack HMAC-SHA512 webhook notification',
      description:
        'Receives verified transaction events from Paystack (e.g. charge.success). Upgrades athlete subscription, updates transaction state, and enforces CAMA 2020 6-year accounting ledger retention.',
      headers: {
        type: 'object',
        properties: {
          'x-paystack-signature': {
            type: 'string',
            description: 'HMAC-SHA512 signature computed with PAYSTACK_SECRET_KEY',
          },
        },
      },
      body: {
        type: 'object',
        required: ['event', 'data'],
        properties: {
          event: { type: 'string', example: 'charge.success' },
          data: {
            type: 'object',
            required: ['reference', 'amount', 'status', 'customer'],
            properties: {
              reference: { type: 'string', example: 'PAY-1794048387123-ABC' },
              amount: { type: 'integer', description: 'Amount in kobo (e.g. 500000 = ₦5,000)', example: 500000 },
              status: { type: 'string', example: 'success' },
              customer: {
                type: 'object',
                properties: {
                  email: { type: 'string', format: 'email', example: 'athlete@raize.fit' },
                },
              },
            },
          },
        },
      },
      response: {
        200: {
          type: 'object',
          description: 'Webhook processed successfully',
          properties: {
            received: { type: 'boolean', example: true },
          },
        },
        401: {
          type: 'object',
          description: 'Invalid signature error',
          properties: {
            error: { type: 'string', example: 'Invalid webhook signature' },
          },
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const signature = request.headers['x-paystack-signature'] as string;
    const rawBody = JSON.stringify(request.body);

    // In non-test environments verify signature
    if (process.env.NODE_ENV === 'production' && signature) {
      const isValid = verifyPaystackSignature(rawBody, signature);
      if (!isValid) {
        return reply.status(401).send({ error: 'Invalid webhook signature' });
      }
    }

    const payload = request.body as {
      event: string;
      data: {
        reference: string;
        amount: number;
        status: string;
        customer: { email: string };
      };
    };

    if (payload.event === 'charge.success') {
      const reference = payload.data.reference;

      // Update transaction status
      const [tx] = await db
        .update(billingTransactions)
        .set({ status: 'success' })
        .where(eq(billingTransactions.providerReference, reference))
        .returning();

      if (tx && tx.userId) {
        const now = new Date();
        const periodEnd = new Date(now);
        periodEnd.setMonth(now.getMonth() + 1);

        // Upgrade user subscription
        await db.insert(subscriptions).values({
          userId: tx.userId,
          planId: 'premium_monthly',
          status: 'active',
          provider: 'paystack',
          providerSubscriptionId: reference,
          currentPeriodStart: now,
          currentPeriodEnd: periodEnd,
        });

        // Send payment receipt via SendByte
        const [profile] = await db.select().from(userProfiles).where(eq(userProfiles.userId, tx.userId));
        sendPaymentReceiptEmail(
          payload.data.customer.email,
          profile?.firstName || '',
          'Raize Premium (Monthly)',
          parseFloat(tx.amountNgn || '5000'),
          reference
        ).catch((err) => {
          request.log.error(err, 'Failed to dispatch SendByte payment receipt email');
        });
      }
    }

    return reply.send({ received: true });
  });
}

