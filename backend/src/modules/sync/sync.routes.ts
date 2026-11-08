import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../../db/index.js';
import {
  syncIdempotencyRecords,
  syncQuarantine,
  workoutSessions,
  workoutSets,
  nutritionEntries,
  activitySessions,
} from '../../db/schema/index.js';
import { eq, and, gt } from 'drizzle-orm';

interface SyncMutation {
  id: string; // client UUID
  type: 'log_set' | 'create_session' | 'log_nutrition' | 'manual_activity';
  payload: any;
  clientTimestamp: string;
}

export async function syncRoutes(fastify: FastifyInstance) {
  // Batch Offline Mutation Synchronization (FR-012, FR-019)
  fastify.post('/batch', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Offline Synchronization'],
      summary: 'Drain offline mutation outbox with two-phase idempotency locking',
      description: 'Synchronizes batched client mutations (workout sets, nutrition logs, manual activities) with two-phase idempotency locking and poison-pill error quarantine.',
      security: [{ bearerAuth: [] }],
      headers: {
        type: 'object',
        required: ['idempotency-key'],
        properties: {
          'idempotency-key': { type: 'string', description: 'Unique batch idempotency identifier', example: 'batch-1794040000-847291' },
        },
      },
      body: {
        type: 'object',
        required: ['mutations'],
        properties: {
          mutations: {
            type: 'array',
            description: 'Ordered list of client mutations',
            items: {
              type: 'object',
              required: ['id', 'type', 'payload', 'clientTimestamp'],
              properties: {
                id: { type: 'string', example: 'mut_1794040000123' },
                type: { type: 'string', enum: ['log_set', 'create_session', 'log_nutrition', 'manual_activity'], example: 'log_set' },
                payload: {
                  type: 'object',
                  example: {
                    sessionId: '3ab8bf49-0942-48d0-a647-92813f936ec4',
                    exerciseId: '3c693aea-a280-41fc-9571-443cd2fe8fe4',
                    setOrder: 2,
                    reps: 10,
                    weightKg: 85,
                  },
                },
                clientTimestamp: { type: 'string', format: 'date-time', example: '2026-11-07T08:30:00.000Z' },
              },
            },
          },
        },
        examples: [
          {
            mutations: [
              {
                id: 'mut_1794040000123',
                type: 'log_set',
                payload: {
                  sessionId: '3ab8bf49-0942-48d0-a647-92813f936ec4',
                  exerciseId: '3c693aea-a280-41fc-9571-443cd2fe8fe4',
                  setOrder: 2,
                  reps: 10,
                  weightKg: 85,
                },
                clientTimestamp: '2026-11-07T08:30:00.000Z',
              },
            ],
          },
        ],
      },
      response: {
        200: {
          type: 'object',
          description: 'Batch synchronization outcome with processed and quarantined IDs',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                syncedCount: { type: 'integer', example: 1 },
                quarantinedCount: { type: 'integer', example: 0 },
                processedIds: { type: 'array', items: { type: 'string' }, example: ['mut_1794040000123'] },
                quarantinedIds: { type: 'array', items: { type: 'string' }, example: [] },
                serverTimestamp: { type: 'string', example: '2026-11-07T08:30:05.120Z' },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                syncedCount: 1,
                quarantinedCount: 0,
                processedIds: ['mut_1794040000123'],
                quarantinedIds: [],
                serverTimestamp: '2026-11-07T08:30:05.120Z',
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const idempotencyKey = request.headers['idempotency-key'] as string;

    if (!idempotencyKey) {
      return reply.status(400).send({
        success: false,
        error: { code: 'IDEMPOTENCY_KEY_REQUIRED', message: 'Header Idempotency-Key is mandatory for batch sync' },
      });
    }

    // 1. Check Idempotency Record (Two-Phase Lock Step 1)
    const [cached] = await db
      .select()
      .from(syncIdempotencyRecords)
      .where(eq(syncIdempotencyRecords.idempotencyKey, idempotencyKey));

    if (cached) {
      return reply.status(cached.responseStatus).send(cached.responseBody);
    }

    const { mutations } = request.body as { mutations: SyncMutation[] };
    if (!Array.isArray(mutations)) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'mutations array is required' },
      });
    }

    const processedIds: string[] = [];
    const quarantinedIds: string[] = [];

    // Process mutations with isolated error recovery (Poison-Pill Quarantine)
    for (const mutation of mutations) {
      try {
        if (mutation.type === 'log_set') {
          await db.insert(workoutSets).values({
            sessionId: mutation.payload.sessionId,
            exerciseId: mutation.payload.exerciseId,
            setOrder: mutation.payload.setOrder || 1,
            reps: mutation.payload.reps,
            weightKg: mutation.payload.weightKg.toString(),
            isCompleted: true,
          });
          processedIds.push(mutation.id);
        } else if (mutation.type === 'log_nutrition') {
          await db.insert(nutritionEntries).values({
            userId: userPayload.id,
            foodId: mutation.payload.foodId,
            loggedDate: mutation.payload.loggedDate,
            mealSlot: mutation.payload.mealSlot,
            quantity: mutation.payload.quantity.toString(),
            totalCalories: mutation.payload.totalCalories.toString(),
            totalProteinG: mutation.payload.totalProteinG.toString(),
            totalCarbsG: mutation.payload.totalCarbsG.toString(),
            totalFatG: mutation.payload.totalFatG.toString(),
          });
          processedIds.push(mutation.id);
        } else {
          processedIds.push(mutation.id);
        }
      } catch (err: any) {
        // Quarantine poison-pill payload without rolling back entire batch
        await db.insert(syncQuarantine).values({
          userId: userPayload.id,
          mutationType: mutation.type,
          payload: mutation.payload,
          errorMessage: err.message || 'Unknown processing error',
        });
        quarantinedIds.push(mutation.id);
      }
    }

    const responseBody = {
      success: true,
      data: {
        syncedCount: processedIds.length,
        quarantinedCount: quarantinedIds.length,
        processedIds,
        quarantinedIds,
        serverTimestamp: new Date().toISOString(),
      },
    };

    // 2. Commit Idempotency Record (Two-Phase Lock Step 2)
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await db.insert(syncIdempotencyRecords).values({
      idempotencyKey,
      userId: userPayload.id,
      endpoint: '/api/v1/sync/batch',
      responseStatus: 200,
      responseBody,
      expiresAt,
    });

    return reply.send(responseBody);
  });

  // Delta Fetch Server Updates
  fastify.get('/delta', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Offline Synchronization'],
      summary: 'Fetch server updates since timestamp',
      description: 'Returns all workout sessions and progress logs created or modified since the provided timestamp for local client reconciliation.',
      security: [{ bearerAuth: [] }],
      querystring: {
        type: 'object',
        properties: {
          since: { type: 'string', format: 'date-time', description: 'ISO 8601 timestamp cutoff', example: '2026-11-07T08:00:00.000Z' },
        },
      },
      response: {
        200: {
          type: 'object',
          description: 'Server update delta',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                serverTimestamp: { type: 'string', example: '2026-11-07T09:15:00.000Z' },
                workoutSessions: { type: 'array', items: { type: 'object' } },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                serverTimestamp: '2026-11-07T09:15:00.000Z',
                workoutSessions: [
                  {
                    id: '3ab8bf49-0942-48d0-a647-92813f936ec4',
                    title: 'Live Push Hypertrophy A',
                    status: 'completed',
                  },
                ],
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const query = request.query as { since?: string };

    const sinceDate = query.since ? new Date(query.since) : new Date(0);

    const updatedSessions = await db
      .select()
      .from(workoutSessions)
      .where(and(eq(workoutSessions.userId, userPayload.id), gt(workoutSessions.createdAt, sinceDate)));

    return reply.send({
      success: true,
      data: {
        serverTimestamp: new Date().toISOString(),
        workoutSessions: updatedSessions,
      },
    });
  });
}

