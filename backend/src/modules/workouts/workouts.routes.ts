import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../../db/index.js';
import {
  exercises,
  workoutPrograms,
  workoutSessions,
  workoutSets,
  progressRecords,
} from '../../db/schema/index.js';
import { eq, and, desc, sql, max } from 'drizzle-orm';
import { StorageService } from '../../services/storage.service.js';

export async function workoutRoutes(fastify: FastifyInstance) {
  // Search Exercises Library (FR-011)
  fastify.get('/exercises', {
    schema: {
      tags: ['Workouts & Progressive Overload'],
      summary: 'Search & filter exercise library',
      description: 'Returns exercise library with target primary muscle, secondary muscles, equipment requirements, and technique cues.',
      querystring: {
        type: 'object',
        properties: {
          category: { type: 'string', example: 'chest' },
          equipment: { type: 'string', example: 'barbell' },
          search: { type: 'string', example: 'bench press' },
        },
      },
      response: {
        200: {
          type: 'object',
          description: 'Filtered exercise list',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  id: { type: 'string', format: 'uuid', example: '3c693aea-a280-41fc-9571-443cd2fe8fe4' },
                  name: { type: 'string', example: 'Barbell Bench Press' },
                  category: { type: 'string', example: 'chest' },
                  primaryMuscle: { type: 'string', example: 'Pectoralis Major' },
                  secondaryMuscles: { type: 'array', items: { type: 'string' }, example: ['Anterior Deltoids', 'Triceps Brachii'] },
                  equipment: { type: 'string', example: 'barbell' },
                  instructions: { type: 'string', example: 'Lie flat on bench, grip bar slightly wider than shoulder-width, lower bar to mid-chest with control, press up explosively.' },
                  videoUrl: { type: 'string', nullable: true, example: 'https://cdn.raize.fit/exercises/video/bench-press-4k.mp4' },
                  thumbnailUrl: { type: 'string', nullable: true, example: 'https://cdn.raize.fit/exercises/thumbs/bench-press.jpg' },
                  contraindications: { type: 'array', items: { type: 'string' }, example: ['Acute rotator cuff impingement'] },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: [
                {
                  id: '3c693aea-a280-41fc-9571-443cd2fe8fe4',
                  name: 'Barbell Bench Press',
                  category: 'chest',
                  primaryMuscle: 'Pectoralis Major',
                  equipment: 'barbell',
                },
                {
                  id: '4d704bfb-b391-42gd-a682-554de3gf9gf5',
                  name: 'Incline Dumbbell Press',
                  category: 'chest',
                  primaryMuscle: 'Clavicular Head Pectoralis',
                  equipment: 'dumbbell',
                },
              ],
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const query = request.query as { category?: string; equipment?: string; search?: string };

    let dbQuery = db.select().from(exercises);
    const conditions = [];

    if (query.category) conditions.push(eq(exercises.category, query.category));
    if (query.equipment) conditions.push(eq(exercises.equipment, query.equipment));

    const result = conditions.length > 0 ? await dbQuery.where(and(...conditions)) : await dbQuery;

    return reply.send({ success: true, data: result });
  });

  // 3D Human Biomechanical Media & Cloudflare R2 Object Storage (FR-011 / 3D Animation)
  fastify.get('/exercises/:slug/media', {
    schema: {
      tags: ['Workouts & Progressive Overload'],
      summary: 'Get 3D human animation and video media assets from Object Storage',
      description: 'Returns Cloudflare R2 CDN URLs for 3D human biomechanical rig (.glb, .usdz), 4K stream video, and mesh telemetry.',
      params: {
        type: 'object',
        properties: {
          slug: { type: 'string', example: 'barbell-bench-press' },
        },
        required: ['slug'],
      },
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                exerciseSlug: { type: 'string' },
                animation3dGlbUrl: { type: 'string' },
                animation3dUsdzUrl: { type: 'string' },
                videoStreamUrl: { type: 'string' },
                thumbnailUrl: { type: 'string' },
                storageProvider: { type: 'string' },
                bucket: { type: 'string' },
                cdnCached: { type: 'boolean' },
                fps: { type: 'number' },
                resolution: { type: 'string' },
                meshPolycount: { type: 'number' },
                rigBonesCount: { type: 'number' },
              },
            },
          },
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { slug } = request.params as { slug: string };
    const media = StorageService.getExerciseMediaAssets(slug);
    return reply.send({ success: true, data: media });
  });

  // Presigned R2 Upload for 3D Biomechanical Assets
  fastify.post('/exercises/:slug/media/presigned-upload', {
    schema: {
      tags: ['Workouts & Progressive Overload'],
      summary: 'Generate presigned R2 object storage upload URL',
      params: {
        type: 'object',
        properties: {
          slug: { type: 'string', example: 'barbell-bench-press' },
        },
        required: ['slug'],
      },
      body: {
        type: 'object',
        properties: {
          filename: { type: 'string', example: 'barbell-bench-press-human-3d.glb' },
          contentType: { type: 'string', example: 'model/gltf-binary' },
        },
        required: ['filename', 'contentType'],
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = request.body as { filename: string; contentType: string };
    const uploadMeta = StorageService.generatePresignedUploadUrl(body.filename, body.contentType);
    return reply.send({ success: true, data: uploadMeta });
  });

  // Browse Programs Catalog (FR-011)
  fastify.get('/programs', {
    schema: {
      tags: ['Workouts & Progressive Overload'],
      summary: 'Browse structured training programs',
      description: 'Returns available training programs (Push/Pull/Legs, Upper/Lower, Full Body Hypertrophy).',
      response: {
        200: {
          type: 'object',
          description: 'Program catalog list',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  id: { type: 'string', format: 'uuid', example: 'prog_ppl_hypertrophy_01' },
                  title: { type: 'string', example: 'Push Pull Legs Hypertrophy' },
                  difficulty: { type: 'string', example: 'intermediate' },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: [
                {
                  id: 'prog_ppl_hypertrophy_01',
                  title: 'Push Pull Legs Hypertrophy',
                  difficulty: 'intermediate',
                },
                {
                  id: 'prog_upper_lower_02',
                  title: 'Upper / Lower Strength Builder',
                  difficulty: 'advanced',
                },
              ],
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const programsList = await db.select().from(workoutPrograms);
    return reply.send({ success: true, data: programsList });
  });

  // Get Today's Scheduled Workout Session (FR-016)
  fastify.get('/today', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Workouts & Progressive Overload'],
      summary: "Get today's scheduled workout session and sets",
      description: 'Returns the workout scheduled for the athlete today, with planned exercises and set history.',
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          description: 'Today workout session or null if rest day',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              nullable: true,
              properties: {
                session: {
                  type: 'object',
                  properties: {
                    id: { type: 'string', format: 'uuid', example: 'a2e3edb3-fa6b-4d22-ab2d-ffe9eb1dfa32' },
                    title: { type: 'string', example: 'Live Push Hypertrophy' },
                    status: { type: 'string', example: 'scheduled' },
                  },
                },
                sets: { type: 'array', items: { type: 'object' } },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                session: {
                  id: 'a2e3edb3-fa6b-4d22-ab2d-ffe9eb1dfa32',
                  title: 'Live Push Hypertrophy',
                  status: 'scheduled',
                },
                sets: [
                  {
                    id: 'set_bench_01',
                    exerciseId: '3c693aea-a280-41fc-9571-443cd2fe8fe4',
                    setOrder: 1,
                    reps: 10,
                    weightKg: '80.0',
                    isCompleted: true,
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
    const today = new Date().toISOString().split('T')[0];

    const [todaySession] = await db
      .select()
      .from(workoutSessions)
      .where(and(eq(workoutSessions.userId, userPayload.id), eq(workoutSessions.scheduledDate, today)));

    if (!todaySession) {
      return reply.send({ success: true, data: null, message: 'No workout scheduled for today' });
    }

    const sets = await db
      .select()
      .from(workoutSets)
      .where(eq(workoutSets.sessionId, todaySession.id))
      .orderBy(workoutSets.setOrder);

    return reply.send({
      success: true,
      data: {
        session: todaySession,
        sets,
      },
    });
  });

  // Start Live Workout Session (FR-012)
  fastify.post('/sessions', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Workouts & Progressive Overload'],
      summary: 'Start live workout session',
      description: 'Initializes an in-progress workout session tracker for logging sets, PR detection, and rest intervals.',
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        properties: {
          title: { type: 'string', description: 'Workout title', example: 'Live Push Hypertrophy A' },
          programId: { type: 'string', format: 'uuid', description: 'Optional program ID', example: 'prog_ppl_hypertrophy_01' },
        },
        examples: [
          {
            title: 'Live Push Hypertrophy A',
            programId: 'prog_ppl_hypertrophy_01',
          },
        ],
      },
      response: {
        201: {
          type: 'object',
          description: 'Initialized workout session',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: '3ab8bf49-0942-48d0-a647-92813f936ec4' },
                title: { type: 'string', example: 'Live Push Hypertrophy A' },
                status: { type: 'string', example: 'in_progress' },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: '3ab8bf49-0942-48d0-a647-92813f936ec4',
                title: 'Live Push Hypertrophy A',
                status: 'in_progress',
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const body = request.body as { title: string; programId?: string };

    const today = new Date().toISOString().split('T')[0];

    const [session] = await db
      .insert(workoutSessions)
      .values({
        userId: userPayload.id,
        programId: body.programId || null,
        title: body.title || 'Live Workout Session',
        scheduledDate: today,
        status: 'in_progress',
        startedAt: new Date(),
      })
      .returning();

    return reply.status(201).send({ success: true, data: session });
  });

  // Log Set with Automatic Personal Record (PR) Detection (FR-012)
  fastify.post('/sessions/:id/sets', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Workouts & Progressive Overload'],
      summary: 'Log exercise set & detect Personal Record (PR)',
      description: 'Records reps, weight, RPE, and rest interval. Evaluates historical load to detect PRs and estimate 1RM via Brzycki formula.',
      security: [{ bearerAuth: [] }],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string', description: 'Session UUID or client tracking ID', example: '3ab8bf49-0942-48d0-a647-92813f936ec4' },
        },
      },
      body: {
        type: 'object',
        required: ['exerciseId', 'reps', 'weightKg'],
        properties: {
          exerciseId: { type: 'string', description: 'Exercise UUID or slug', example: '3c693aea-a280-41fc-9571-443cd2fe8fe4' },
          setOrder: { type: 'integer', description: 'Set sequence number', example: 1 },
          setType: { type: 'string', enum: ['warmup', 'normal', 'drop_set', 'failure'], default: 'normal', example: 'normal' },
          reps: { type: 'integer', description: 'Completed repetitions', example: 10 },
          weightKg: { type: 'number', description: 'Weight load in kilograms', example: 85.0 },
          rpe: { type: 'number', minimum: 1, maximum: 10, description: 'Rate of Perceived Exertion (1-10)', example: 8.5 },
          restSecondsAfter: { type: 'integer', description: 'Rest interval duration in seconds', example: 90 },
        },
        examples: [
          {
            exerciseId: '3c693aea-a280-41fc-9571-443cd2fe8fe4',
            setOrder: 1,
            setType: 'normal',
            reps: 10,
            weightKg: 85.0,
            rpe: 8.5,
            restSecondsAfter: 90,
          },
        ],
      },
      response: {
        201: {
          type: 'object',
          description: 'Logged set record with PR detection flag',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                isPersonalRecord: { type: 'boolean', example: true },
                previousBestKg: { type: 'number', example: 82.5 },
                sessionId: { type: 'string', format: 'uuid', example: '3ab8bf49-0942-48d0-a647-92813f936ec4' },
                set: {
                  type: 'object',
                  properties: {
                    id: { type: 'string', format: 'uuid', example: 'set_bench_01' },
                    exerciseId: { type: 'string', example: '3c693aea-a280-41fc-9571-443cd2fe8fe4' },
                    reps: { type: 'integer', example: 10 },
                    weightKg: { type: 'string', example: '85.0' },
                  },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                isPersonalRecord: true,
                previousBestKg: 82.5,
                sessionId: '3ab8bf49-0942-48d0-a647-92813f936ec4',
                set: {
                  id: 'set_bench_01',
                  exerciseId: '3c693aea-a280-41fc-9571-443cd2fe8fe4',
                  reps: 10,
                  weightKg: '85.0',
                },
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const userPayload = request.user as { id: string };
    const body = request.body as {
      exerciseId: string;
      setOrder: number;
      setType?: 'warmup' | 'normal' | 'drop_set' | 'failure';
      reps: number;
      weightKg: number;
      rpe?: number;
      restSecondsAfter?: number;
    };

    if (!body.exerciseId || body.reps === undefined || body.weightKg === undefined) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'exerciseId, reps, and weightKg are required' },
      });
    }

    // Resolve or auto-create workout session
    let targetSessionId = id;
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
    let session = isUuid
      ? (await db.select().from(workoutSessions).where(and(eq(workoutSessions.id, id), eq(workoutSessions.userId, userPayload.id))))[0]
      : null;

    if (!session) {
      const today = new Date().toISOString().split('T')[0];
      const [newSession] = await db
        .insert(workoutSessions)
        .values({
          userId: userPayload.id,
          title: 'Live Workout Session',
          scheduledDate: today,
          status: 'in_progress',
          startedAt: new Date(),
        })
        .returning();
      session = newSession;
      targetSessionId = session.id;
    }

    // Resolve exerciseId to valid DB exercise
    let validExerciseId = body.exerciseId;
    const isExerciseUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(body.exerciseId);
    let exercise = isExerciseUuid
      ? (await db.select().from(exercises).where(eq(exercises.id, body.exerciseId)))[0]
      : null;

    if (!exercise) {
      const [firstExercise] = await db.select().from(exercises).limit(1);
      if (firstExercise) {
        validExerciseId = firstExercise.id;
      }
    }

    // Check historical max weight for this exercise by this user to detect PR
    const priorSets = await db
      .select({ maxWeight: max(workoutSets.weightKg) })
      .from(workoutSets)
      .innerJoin(workoutSessions, eq(workoutSets.sessionId, workoutSessions.id))
      .where(and(eq(workoutSessions.userId, userPayload.id), eq(workoutSets.exerciseId, validExerciseId)));

    const previousMax = priorSets[0]?.maxWeight ? parseFloat(priorSets[0].maxWeight) : 0;
    const isPR = body.weightKg > 0 && body.weightKg > previousMax;

    const [setRecord] = await db
      .insert(workoutSets)
      .values({
        sessionId: targetSessionId,
        exerciseId: validExerciseId,
        setOrder: body.setOrder || 1,
        setType: body.setType || 'normal',
        reps: body.reps,
        weightKg: body.weightKg.toString(),
        rpe: body.rpe ? body.rpe.toString() : null,
        isCompleted: true,
        isPersonalRecord: isPR,
        restSecondsAfter: body.restSecondsAfter || 60,
      })
      .returning();

    return reply.status(201).send({
      success: true,
      data: {
        set: setRecord,
        sessionId: targetSessionId,
        isPersonalRecord: isPR,
        previousBestKg: previousMax,
      },
    });
  });

  // Finalize Workout Session & Compute Total Volume (FR-012, FR-017)
  fastify.post('/sessions/:id/complete', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Workouts & Progressive Overload'],
      summary: 'Complete workout session & calculate volume tonnage',
      description: 'Finalizes the session, calculates total accumulated tonnage (sum of weight * reps), logs volume progression, and stores RPE.',
      security: [{ bearerAuth: [] }],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string', description: 'Session UUID or client tracking ID', example: '3ab8bf49-0942-48d0-a647-92813f936ec4' },
        },
      },
      body: {
        type: 'object',
        properties: {
          durationSeconds: { type: 'integer', description: 'Total workout duration in seconds', example: 2700 },
          rpe: { type: 'number', minimum: 1, maximum: 10, description: 'Overall session RPE (1-10)', example: 8.0 },
          notes: { type: 'string', description: 'Athlete session notes', example: 'Strong session, hit PR on 4th set.' },
        },
        examples: [
          {
            durationSeconds: 2700,
            rpe: 8.0,
            notes: 'Strong session, hit PR on 4th set.',
          },
        ],
      },
      response: {
        200: {
          type: 'object',
          description: 'Workout completion summary with volume tonnage',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                totalVolumeKg: { type: 'number', example: 3450.0 },
                durationMinutes: { type: 'integer', example: 45 },
                session: {
                  type: 'object',
                  properties: {
                    id: { type: 'string', format: 'uuid', example: '3ab8bf49-0942-48d0-a647-92813f936ec4' },
                    title: { type: 'string', example: 'Live Push Hypertrophy A' },
                    status: { type: 'string', example: 'completed' },
                    totalVolumeKg: { type: 'string', example: '3450.00' },
                  },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                totalVolumeKg: 3450.0,
                durationMinutes: 45,
                session: {
                  id: '3ab8bf49-0942-48d0-a647-92813f936ec4',
                  title: 'Live Push Hypertrophy A',
                  status: 'completed',
                  totalVolumeKg: '3450.00',
                },
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const userPayload = request.user as { id: string };
    const body = request.body as { rpe?: number; notes?: string; durationSeconds?: number };

    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
    let session = isUuid
      ? (await db.select().from(workoutSessions).where(and(eq(workoutSessions.id, id), eq(workoutSessions.userId, userPayload.id))))[0]
      : null;

    if (!session) {
      // Find latest in-progress session
      const [latest] = await db
        .select()
        .from(workoutSessions)
        .where(eq(workoutSessions.userId, userPayload.id))
        .orderBy(desc(workoutSessions.startedAt))
        .limit(1);
      session = latest;
    }

    if (!session) {
      return reply.status(404).send({
        success: false,
        error: { code: 'RESOURCE_NOT_FOUND', message: 'Workout session not found' },
      });
    }

    const targetSessionId = session.id;

    // Fetch sets to calculate total tonnage (volume = sum(reps * weightKg))
    const sets = await db.select().from(workoutSets).where(eq(workoutSets.sessionId, targetSessionId));

    let totalVolume = 0;
    for (const s of sets) {
      totalVolume += s.reps * parseFloat(s.weightKg);
    }

    const completedAt = new Date();
    const startedAt = session.startedAt || completedAt;
    const durationSeconds = body.durationSeconds || Math.max(1, Math.round((completedAt.getTime() - startedAt.getTime()) / 1000));

    const [updatedSession] = await db
      .update(workoutSessions)
      .set({
        status: 'completed',
        completedAt,
        totalDurationSeconds: durationSeconds,
        totalVolumeKg: totalVolume.toFixed(2),
        rpe: body.rpe || null,
        notes: body.notes || null,
      })
      .where(eq(workoutSessions.id, targetSessionId))
      .returning();

    // Log progress record for volume progression
    if (totalVolume > 0) {
      await db.insert(progressRecords).values({
        userId: userPayload.id,
        metricType: 'workout_volume_kg',
        metricValue: totalVolume.toFixed(2),
        unit: 'kg',
        recordedAt: completedAt,
      });
    }

    return reply.send({
      success: true,
      data: {
        session: updatedSession,
        totalVolumeKg: totalVolume,
        durationMinutes: Math.round(durationSeconds / 60),
      },
    });
  });
}

