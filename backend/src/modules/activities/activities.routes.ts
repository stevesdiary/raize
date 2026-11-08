import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../../db/index.js';
import {
  activitySessions,
  activityRoutes as activityRoutesTable,
  userPrivacyZones,
  progressRecords,
} from '../../db/schema/index.js';
import { eq, and } from 'drizzle-orm';
import { maskPrivacyZones } from '../../utils/calculator.js';

export async function activityRoutes(fastify: FastifyInstance) {
  // Manual Activity Logging (FR-013)
  fastify.post('/manual', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Activities & GPS Telemetry'],
      summary: 'Manually log an activity session',
      description: 'Records workouts or conditioning sessions performed without live GPS (cycling, swimming, calisthenics).',
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['activityType', 'durationSeconds'],
        properties: {
          activityType: { type: 'string', description: 'Activity category', example: 'cycling' },
          durationSeconds: { type: 'integer', description: 'Duration in seconds', example: 1800 },
          distanceMeters: { type: 'number', description: 'Distance in meters', example: 8500 },
          caloriesBurned: { type: 'integer', description: 'Estimated calories burned', example: 340 },
          perceivedExertion: { type: 'number', minimum: 1, maximum: 10, description: 'RPE 1-10', example: 7 },
          notes: { type: 'string', description: 'Athlete activity notes', example: 'Lekki-Ikoyi Link Bridge loop ride.' },
        },
        examples: [
          {
            activityType: 'cycling',
            durationSeconds: 1800,
            distanceMeters: 8500,
            caloriesBurned: 340,
            perceivedExertion: 7,
            notes: 'Lekki-Ikoyi Link Bridge loop ride.',
          },
        ],
      },
      response: {
        201: {
          type: 'object',
          description: 'Created activity session record',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: 'act_cycling_01' },
                activityType: { type: 'string', example: 'cycling' },
                durationSeconds: { type: 'integer', example: 1800 },
                isManual: { type: 'boolean', example: true },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: '55291026-4ddd-460a-ab59-e93d60ec95fe',
                activityType: 'cycling',
                durationSeconds: 1800,
                isManual: true,
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const body = request.body as {
      activityType: string;
      durationSeconds: number;
      distanceMeters?: number;
      caloriesBurned?: number;
      perceivedExertion?: number;
      notes?: string;
    };

    if (!body.activityType || !body.durationSeconds) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'activityType and durationSeconds are required' },
      });
    }

    const now = new Date();
    const startedAt = new Date(now.getTime() - body.durationSeconds * 1000);

    const [session] = await db
      .insert(activitySessions)
      .values({
        userId: userPayload.id,
        activityType: body.activityType,
        startedAt,
        completedAt: now,
        durationSeconds: body.durationSeconds,
        distanceMeters: (body.distanceMeters || 0).toString(),
        caloriesBurned: body.caloriesBurned || 0,
        perceivedExertion: body.perceivedExertion || null,
        isManual: true,
        notes: body.notes || null,
      })
      .returning();

    return reply.status(201).send({ success: true, data: session });
  });

  // Start GPS Activity (FR-019)
  fastify.post('/gps/start', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Activities & GPS Telemetry'],
      summary: 'Start live GPS outdoor tracking session',
      description: 'Initializes an outdoor telemetry run session with live pace, elevation gain, and location polling.',
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        properties: {
          activityType: { type: 'string', default: 'running', example: 'running' },
        },
        examples: [
          {
            activityType: 'running',
          },
        ],
      },
      response: {
        201: {
          type: 'object',
          description: 'Live GPS activity session record',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: '44191026-4ddd-460a-ab59-e93d60ec95fd' },
                activityType: { type: 'string', example: 'running' },
                isManual: { type: 'boolean', example: false },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: '44191026-4ddd-460a-ab59-e93d60ec95fd',
                activityType: 'running',
                isManual: false,
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const body = request.body as { activityType: string };

    const [session] = await db
      .insert(activitySessions)
      .values({
        userId: userPayload.id,
        activityType: body.activityType || 'running',
        startedAt: new Date(),
        isManual: false,
      })
      .returning();

    return reply.status(201).send({ success: true, data: session });
  });

  // Complete GPS Run & Apply Privacy Masking (FR-019, EXT-002)
  fastify.post('/gps/complete', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Activities & GPS Telemetry'],
      summary: 'Complete GPS run & apply 250m privacy zone masking',
      description: 'Calculates average pace, total elevation, and applies 250m privacy perimeter masking around home/work zones before saving route geometry.',
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        properties: {
          activityId: { type: 'string', description: 'Activity session UUID or client ID', example: '44191026-4ddd-460a-ab59-e93d60ec95fd' },
          durationSeconds: { type: 'integer', description: 'Total moving duration in seconds', example: 1800 },
          distanceMeters: { type: 'number', description: 'Total distance in meters', example: 5200 },
          averagePaceSecPerKm: { type: 'number', description: 'Pace in seconds per kilometer', example: 346 },
          totalElevationGainMeters: { type: 'number', description: 'Elevation gain in meters', example: 45 },
          caloriesBurned: { type: 'integer', description: 'Estimated calories burned', example: 420 },
          rawGpsPoints: {
            type: 'array',
            description: 'Array of telemetry GPS coordinate points',
            example: [
              { lat: 6.4388, lng: 3.4215, alt: 10, time: 1794040000 },
              { lat: 6.4395, lng: 3.4228, alt: 12, time: 1794040060 },
            ],
          },
        },
        examples: [
          {
            activityId: '44191026-4ddd-460a-ab59-e93d60ec95fd',
            durationSeconds: 1800,
            distanceMeters: 5200,
            averagePaceSecPerKm: 346,
            totalElevationGainMeters: 45,
            caloriesBurned: 420,
            rawGpsPoints: [
              { lat: 6.4388, lng: 3.4215, alt: 10, time: 1794040000 },
              { lat: 6.4395, lng: 3.4228, alt: 12, time: 1794040060 },
            ],
          },
        ],
      },
      response: {
        200: {
          type: 'object',
          description: 'GPS completion summary and privacy masking metadata',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                privacyMaskApplied: { type: 'boolean', example: true },
                clippedGpsPointsCount: { type: 'integer', example: 28 },
                session: {
                  type: 'object',
                  properties: {
                    id: { type: 'string', format: 'uuid', example: '44191026-4ddd-460a-ab59-e93d60ec95fd' },
                    distanceMeters: { type: 'string', example: '5200.00' },
                    durationSeconds: { type: 'integer', example: 1800 },
                    caloriesBurned: { type: 'integer', example: 420 },
                  },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                privacyMaskApplied: true,
                clippedGpsPointsCount: 28,
                session: {
                  id: '44191026-4ddd-460a-ab59-e93d60ec95fd',
                  distanceMeters: '5200.00',
                  durationSeconds: 1800,
                  caloriesBurned: 420,
                },
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const body = (request.body as {
      activityId?: string;
      id?: string;
      durationSeconds?: number;
      movingDurationSeconds?: number;
      distanceMeters?: number;
      totalDistanceMeters?: number;
      averagePaceSecPerKm?: number;
      totalElevationGainMeters?: number;
      elevationGainMeters?: number;
      caloriesBurned?: number;
      polylineEncoded?: string;
      rawGpsPoints?: Array<{ lat: number; lng: number; alt?: number; time?: number }>;
    }) || {};

    const activityId = body.activityId || body.id;
    const durationSeconds = body.durationSeconds ?? body.movingDurationSeconds ?? 0;
    const distanceMeters = body.distanceMeters ?? body.totalDistanceMeters ?? 0;
    const totalElevationGainMeters = body.totalElevationGainMeters ?? body.elevationGainMeters ?? 0;

    const isUuid = (str?: string) => !!str && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);

    let [session] = isUuid(activityId)
      ? await db
          .select()
          .from(activitySessions)
          .where(and(eq(activitySessions.id, activityId!), eq(activitySessions.userId, userPayload.id)))
      : [];

    if (!session) {
      const now = new Date();
      const startedAt = new Date(now.getTime() - durationSeconds * 1000);
      const [newSession] = await db
        .insert(activitySessions)
        .values({
          userId: userPayload.id,
          activityType: 'running',
          startedAt,
          isManual: false,
        })
        .returning();
      session = newSession;
    }

    const targetActivityId = session.id;

    // Fetch user privacy zones
    const privacyZones = await db
      .select()
      .from(userPrivacyZones)
      .where(and(eq(userPrivacyZones.userId, userPayload.id), eq(userPrivacyZones.isActive, true)));

    let finalPoints = body.rawGpsPoints || [];
    let privacyMaskApplied = false;

    if (privacyZones.length > 0 && finalPoints.length > 0) {
      const zonesData = privacyZones.map((z) => ({
        centerLatitude: parseFloat(z.centerLatitude),
        centerLongitude: parseFloat(z.centerLongitude),
        radiusMeters: z.radiusMeters,
      }));

      finalPoints = maskPrivacyZones(finalPoints, zonesData);
      privacyMaskApplied = true;
    }

    const completedAt = new Date();

    const [updatedSession] = await db
      .update(activitySessions)
      .set({
        completedAt,
        durationSeconds,
        distanceMeters: distanceMeters.toString(),
        averagePaceSecPerKm: body.averagePaceSecPerKm || null,
        totalElevationGainMeters: totalElevationGainMeters.toString(),
        caloriesBurned: body.caloriesBurned || 0,
      })
      .where(eq(activitySessions.id, targetActivityId))
      .returning();

    await db.insert(activityRoutesTable).values({
      activityId: targetActivityId,
      polylineEncoded: body.polylineEncoded || null,
      rawGpsPoints: finalPoints,
      privacyMaskApplied,
      privacyRadiusMeters: 250,
    });

    // Record distance in progress records
    if (distanceMeters > 0) {
      await db.insert(progressRecords).values({
        userId: userPayload.id,
        metricType: `${session.activityType}_distance_km`,
        metricValue: (distanceMeters / 1000).toFixed(2),
        unit: 'km',
        recordedAt: completedAt,
      });
    }

    return reply.send({
      success: true,
      data: {
        session: updatedSession,
        privacyMaskApplied,
        clippedGpsPointsCount: finalPoints.length,
      },
    });
  });

  // User Privacy Zones Management (EXT-002)
  fastify.post('/privacy-zones', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Activities & GPS Telemetry'],
      summary: 'Create privacy perimeter zone around sensitive location',
      description: 'Configures a geometric exclusion mask (default 250m radius) around home, work, or school to protect athlete privacy.',
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['centerLatitude', 'centerLongitude'],
        properties: {
          label: { type: 'string', default: 'Home', example: 'Home - Victoria Island' },
          centerLatitude: { type: 'number', example: 6.4281 },
          centerLongitude: { type: 'number', example: 3.4219 },
          radiusMeters: { type: 'integer', default: 250, example: 250 },
        },
        examples: [
          {
            label: 'Home - Victoria Island',
            centerLatitude: 6.4281,
            centerLongitude: 3.4219,
            radiusMeters: 250,
          },
        ],
      },
      response: {
        201: {
          type: 'object',
          description: 'Created privacy zone configuration',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: 'zone_vi_home_01' },
                label: { type: 'string', example: 'Home - Victoria Island' },
                radiusMeters: { type: 'integer', example: 250 },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: 'zone_vi_home_01',
                label: 'Home - Victoria Island',
                radiusMeters: 250,
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const body = request.body as {
      label: string;
      centerLatitude: number;
      centerLongitude: number;
      radiusMeters?: number;
    };

    const [zone] = await db
      .insert(userPrivacyZones)
      .values({
        userId: userPayload.id,
        label: body.label || 'Home',
        centerLatitude: body.centerLatitude.toString(),
        centerLongitude: body.centerLongitude.toString(),
        radiusMeters: body.radiusMeters || 250,
      })
      .returning();

    return reply.status(201).send({ success: true, data: zone });
  });

  fastify.get('/privacy-zones', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Activities & GPS Telemetry'],
      summary: 'List user active privacy zones',
      description: 'Returns all configured privacy exclusion masks for the authenticated athlete.',
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          description: 'Array of privacy exclusion zones',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  id: { type: 'string', format: 'uuid', example: 'zone_vi_home_01' },
                  label: { type: 'string', example: 'Home - Victoria Island' },
                  centerLatitude: { type: 'string', example: '6.428100' },
                  centerLongitude: { type: 'string', example: '3.421900' },
                  radiusMeters: { type: 'integer', example: 250 },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: [
                {
                  id: 'zone_vi_home_01',
                  label: 'Home - Victoria Island',
                  centerLatitude: '6.428100',
                  centerLongitude: '3.421900',
                  radiusMeters: 250,
                },
              ],
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const zones = await db.select().from(userPrivacyZones).where(eq(userPrivacyZones.userId, userPayload.id));
    return reply.send({ success: true, data: zones });
  });
}
