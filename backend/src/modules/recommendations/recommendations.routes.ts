import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../../db/index.js';
import {
  fitnessProfiles,
  fitnessAssessments,
  activityCatalog,
  recommendationRuns,
  fitnessRecommendations,
  workoutSessions,
  userProfiles,
} from '../../db/schema/index.js';
import { eq, desc, and } from 'drizzle-orm';
import {
  scoreActivitySuitability,
  generateWeeklySchedule,
  calculateAge,
  UserAssessmentInput,
} from '../../utils/calculator.js';

export async function recommendationRoutes(fastify: FastifyInstance) {
  // Generate Personalized Recommendations & 7-Day Blueprint (FR-008, FR-009)
  fastify.post('/generate', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Recommendations & Blueprint Engine'],
      summary: 'Generate 7-factor scored recommendations and 7-day adaptive blueprint',
      description: 'Executes the recommendation scoring engine against all candidate activities and outputs a balanced 7-day weekly schedule with nutritional guidelines.',
      security: [{ bearerAuth: [] }],
      response: {
        201: {
          type: 'object',
          description: 'Personalized fitness blueprint and scored activity rankings',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                runId: { type: 'string', format: 'uuid', example: 'abc2fa65-dfb7-46e0-8cad-b7eed969fc71' },
                blueprint: {
                  type: 'object',
                  properties: {
                    primaryActivity: { type: 'string', example: 'Bodyweight Resistance Circuit' },
                    supportingActivity: { type: 'string', example: 'Brisk Walking' },
                    weeklyDays: { type: 'integer', example: 3 },
                    sessionDurationMinutes: { type: 'integer', example: 40 },
                    schedule: {
                      type: 'array',
                      items: {
                        type: 'object',
                        properties: {
                          day: { type: 'string', example: 'Monday' },
                          type: { type: 'string', example: 'workout' },
                          activity: { type: 'string', example: 'Bodyweight Resistance Circuit' },
                          durationMinutes: { type: 'integer', example: 40 },
                        },
                      },
                    },
                    nutritionStrategy: { type: 'string', example: 'Aim for a ~500 kcal daily deficit (~1667 kcal/day). Focus on whole protein and high fiber vegetables.' },
                    dailyCaloricTarget: { type: 'integer', example: 1667 },
                  },
                },
                recommendations: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      name: { type: 'string', example: 'Bodyweight Resistance Circuit' },
                      category: { type: 'string', example: 'strength' },
                      score: { type: 'number', example: 92.5 },
                    },
                  },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                runId: 'abc2fa65-dfb7-46e0-8cad-b7eed969fc71',
                blueprint: {
                  primaryActivity: 'Bodyweight Resistance Circuit',
                  supportingActivity: 'Brisk Walking',
                  weeklyDays: 3,
                  sessionDurationMinutes: 40,
                  schedule: [
                    { day: 'Monday', type: 'workout', activity: 'Bodyweight Resistance Circuit', durationMinutes: 40 },
                    { day: 'Tuesday', type: 'rest', activity: 'Active Recovery / Rest', durationMinutes: 0 },
                    { day: 'Wednesday', type: 'workout', activity: 'Bodyweight Resistance Circuit', durationMinutes: 40 },
                    { day: 'Thursday', type: 'rest', activity: 'Active Recovery / Rest', durationMinutes: 0 },
                    { day: 'Friday', type: 'workout', activity: 'Brisk Walking', durationMinutes: 30 },
                    { day: 'Saturday', type: 'rest', activity: 'Active Recovery / Rest', durationMinutes: 0 },
                    { day: 'Sunday', type: 'rest', activity: 'Active Recovery / Rest', durationMinutes: 0 },
                  ],
                  nutritionStrategy: 'Aim for a ~500 kcal daily deficit (~1667 kcal/day). Focus on whole protein and high fiber vegetables.',
                  dailyCaloricTarget: 1667,
                },
                recommendations: [
                  { name: 'Bodyweight Resistance Circuit', category: 'strength', score: 92.5 },
                  { name: 'Brisk Walking', category: 'cardio', score: 86.0 },
                  { name: 'Outdoor Jogging', category: 'cardio', score: 78.5 },
                ],
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };

    // 1. Fetch user fitness profile
    const [profile] = await db.select().from(fitnessProfiles).where(eq(fitnessProfiles.userId, userPayload.id));
    if (!profile) {
      return reply.status(400).send({
        success: false,
        error: { code: 'ASSESSMENT_REQUIRED', message: 'User must complete an assessment before recommendations can be generated' },
      });
    }

    // 2. Safety Intercept: Medical lock if cardiac symptoms are active
    if (profile.safetyStatus === 'exercise_paused_pending_assessment') {
      return reply.status(403).send({
        success: false,
        error: {
          code: 'SAFETY_INTERCEPT_ACTIVE',
          message: 'Exercise recommendations are currently paused due to reported cardiac or safety symptoms. Medical clearance is required.',
        },
      });
    }

    // 3. Fetch latest completed assessment responses
    const [assessment] = await db
      .select()
      .from(fitnessAssessments)
      .where(and(eq(fitnessAssessments.userId, userPayload.id), eq(fitnessAssessments.status, 'completed')))
      .orderBy(desc(fitnessAssessments.version));

    const responses = (assessment?.responses as Record<string, any>) || {};

    const [userDemographics] = await db.select().from(userProfiles).where(eq(userProfiles.userId, userPayload.id));
    const age = userDemographics ? calculateAge(userDemographics.dateOfBirth) : 25;

    // Assemble input for recommendation engine
    const weeklyDaysRaw = responses['D01'] || '3';
    const weeklyDays = weeklyDaysRaw === '1_2' ? 2 : weeklyDaysRaw === '3' ? 3 : weeklyDaysRaw === '4_5' ? 4 : 5;
    const sessionMinutesRaw = responses['D02'] || '30_45';
    const sessionMinutes = sessionMinutesRaw === '10_15' ? 15 : sessionMinutesRaw === '15_30' ? 30 : sessionMinutesRaw === '45_60' ? 50 : 40;

    const userInput: UserAssessmentInput = {
      age,
      biologicalSex: userDemographics?.biologicalSex as any,
      heightCm: userDemographics?.heightCm ? parseFloat(userDemographics.heightCm) : 175,
      weightKg: userDemographics?.weightKg ? parseFloat(userDemographics.weightKg) : 70,
      primaryGoal: profile.primaryGoal,
      fitnessLevel: profile.experience,
      frequency: responses['C02'] || 'never',
      typicalDay: profile.activityBaseline,
      weeklyDays,
      sessionMinutes,
      environment: profile.trainingEnvironment,
      equipment: responses['D04'] ? (Array.isArray(responses['D04']) ? responses['D04'] : [responses['D04']]) : ['none'],
      enjoyedActivities: responses['D05'] ? (Array.isArray(responses['D05']) ? responses['D05'] : [responses['D05']]) : [],
      avoidedActivities: responses['D06'] ? (Array.isArray(responses['D06']) ? responses['D06'] : [responses['D06']]) : [],
      hasInjury: responses['E01'] === 'yes',
      affectedBodyParts: responses['E01_affected'] ? [responses['E01_affected']] : [],
      criticalCardiacSymptom: responses['E05'] === 'yes' || responses['E05'] === 'prefer_not_to_say',
    };

    // 4. Fetch candidate activities
    const allActivities = await db.select().from(activityCatalog).where(eq(activityCatalog.isPublic, true));

    // 5. Score every candidate activity with 7-factor model
    const scoredList = allActivities
      .map((activity) => {
        const { score, breakdown, isContraindicated } = scoreActivitySuitability(
          {
            category: activity.category,
            primaryGoal: activity.primaryGoal,
            difficultyLevel: activity.difficultyLevel,
            equipmentRequired: activity.equipmentRequired,
            defaultDurationMinutes: activity.defaultDurationMinutes,
            environment: activity.environment,
            contraindications: activity.contraindications,
          },
          userInput
        );
        return {
          activity,
          score,
          breakdown,
          isContraindicated,
        };
      })
      .filter((item) => !item.isContraindicated)
      .sort((a, b) => b.score - a.score);

    const primaryCandidate = scoredList[0]?.activity || allActivities[0];
    const supportingCandidate = scoredList[1]?.activity || scoredList[0]?.activity || allActivities[0];

    // 6. Generate 7-day balanced weekly schedule
    const weeklySchedule = generateWeeklySchedule(
      primaryCandidate.name,
      supportingCandidate.name,
      weeklyDays,
      sessionMinutes
    );

    // 7. Nutrition Strategy
    let nutritionStrategy = 'Balanced energy intake with sufficient hydration.';
    if (profile.primaryGoal === 'weight_management') {
      nutritionStrategy = `Aim for a ~500 kcal daily deficit (~${profile.targetDailyCalories} kcal/day). Focus on whole protein and high fiber vegetables.`;
    } else if (profile.primaryGoal === 'build_muscle' || profile.primaryGoal === 'build_strength') {
      nutritionStrategy = `Caloric surplus of 200–300 kcal (~${profile.targetDailyCalories} kcal/day) with 1.6–2.0g of protein per kg of body weight.`;
    } else if (profile.primaryGoal === 'improve_endurance') {
      nutritionStrategy = `Carbohydrate-focused nutrition to optimize glycogen stores for cardiovascular endurance sessions.`;
    }

    const generatedPlan = {
      primaryActivity: primaryCandidate.name,
      supportingActivity: supportingCandidate.name,
      weeklyDays,
      sessionDurationMinutes: sessionMinutes,
      schedule: weeklySchedule,
      nutritionStrategy,
      dailyCaloricTarget: profile.targetDailyCalories,
    };

    // Deactivate prior runs
    await db
      .update(recommendationRuns)
      .set({ isActive: false })
      .where(eq(recommendationRuns.userId, userPayload.id));

    // Save recommendation run
    const [newRun] = await db
      .insert(recommendationRuns)
      .values({
        userId: userPayload.id,
        assessmentId: assessment?.id || null,
        algorithmVersion: '1.0.0',
        inputSnapshot: userInput,
        generatedPlan,
        requiresProfessionalGuidance: profile.safetyStatus === 'needs_modification',
        safetyStatus: profile.safetyStatus,
        userCanCustomize: true,
        isActive: true,
      })
      .returning();

    // Insert itemized recommendations
    await db.insert(fitnessRecommendations).values([
      {
        runId: newRun.id,
        activityId: primaryCandidate.id,
        activityType: primaryCandidate.code,
        priority: 'primary',
        score: scoredList[0]?.score.toString() || '90',
        scoreBreakdown: scoredList[0]?.breakdown || {},
        explanation: `Strongest alignment with your primary goal (${profile.primaryGoal.replace(/_/g, ' ')}) and available equipment.`,
      },
      {
        runId: newRun.id,
        activityId: supportingCandidate.id,
        activityType: supportingCandidate.code,
        priority: 'supporting',
        score: scoredList[1]?.score.toString() || '80',
        scoreBreakdown: scoredList[1]?.breakdown || {},
        explanation: `Complementary activity enhancing functional conditioning and training balance.`,
      },
    ]);

    return reply.status(201).send({
      success: true,
      data: {
        runId: newRun.id,
        blueprint: generatedPlan,
        recommendations: scoredList.slice(0, 4).map((s) => ({
          name: s.activity.name,
          category: s.activity.category,
          score: s.score,
          breakdown: s.breakdown,
        })),
      },
    });
  });

  // Get Active Blueprint
  fastify.get('/active', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Recommendations & Blueprint Engine'],
      summary: 'Get active 7-day training blueprint',
      description: 'Retrieves the currently accepted fitness schedule, active goals, and caloric targets.',
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          description: 'Active recommendations run and weekly blueprint',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                runId: { type: 'string', format: 'uuid', example: 'abc2fa65-dfb7-46e0-8cad-b7eed969fc71' },
                generatedPlan: {
                  type: 'object',
                  properties: {
                    weeklyDays: { type: 'integer', example: 3 },
                    primaryActivity: { type: 'string', example: 'Bodyweight Resistance Circuit' },
                    dailyCaloricTarget: { type: 'integer', example: 1667 },
                  },
                },
                createdAt: { type: 'string', example: '2026-11-07T08:58:33.478Z' },
                userCanCustomize: { type: 'boolean', example: true },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                runId: 'abc2fa65-dfb7-46e0-8cad-b7eed969fc71',
                generatedPlan: {
                  weeklyDays: 3,
                  primaryActivity: 'Bodyweight Resistance Circuit',
                  supportingActivity: 'Brisk Walking',
                  sessionDurationMinutes: 40,
                  dailyCaloricTarget: 1667,
                  schedule: [
                    { day: 'Monday', type: 'workout', activity: 'Bodyweight Resistance Circuit', durationMinutes: 40 },
                    { day: 'Wednesday', type: 'workout', activity: 'Bodyweight Resistance Circuit', durationMinutes: 40 },
                    { day: 'Friday', type: 'workout', activity: 'Brisk Walking', durationMinutes: 30 },
                  ],
                },
                createdAt: '2026-11-07T08:58:33.478Z',
                userCanCustomize: true,
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };

    const [run] = await db
      .select()
      .from(recommendationRuns)
      .where(and(eq(recommendationRuns.userId, userPayload.id), eq(recommendationRuns.isActive, true)))
      .orderBy(desc(recommendationRuns.createdAt));

    if (!run) {
      return reply.status(404).send({
        success: false,
        error: { code: 'NO_ACTIVE_RECOMMENDATIONS', message: 'No active fitness blueprint found' },
      });
    }

    return reply.send({
      success: true,
      data: {
        runId: run.id,
        generatedPlan: run.generatedPlan,
        createdAt: run.createdAt,
        userCanCustomize: run.userCanCustomize,
      },
    });
  });

  // Activate Active Blueprint and Schedule Workouts
  fastify.post('/activate', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Recommendations & Blueprint Engine'],
      summary: 'Activate latest blueprint & schedule weekly sessions',
      description: 'Schedules workout sessions for the current week based on the active generated blueprint.',
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          description: 'Scheduled workout sessions summary',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                message: { type: 'string', example: 'Fitness blueprint activated and workouts scheduled' },
                scheduledCount: { type: 'integer', example: 3 },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                message: 'Fitness blueprint activated and workouts scheduled',
                scheduledCount: 3,
                sessions: [
                  { id: '11111111-2222-3333-4444-555555555555', title: 'Bodyweight Resistance Circuit Session', scheduledDate: '2026-11-09', status: 'scheduled' },
                  { id: '22222222-3333-4444-5555-666666666666', title: 'Bodyweight Resistance Circuit Session', scheduledDate: '2026-11-11', status: 'scheduled' },
                  { id: '33333333-4444-5555-6666-777777777777', title: 'Brisk Walking Session', scheduledDate: '2026-11-13', status: 'scheduled' },
                ],
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };

    const [run] = await db
      .select()
      .from(recommendationRuns)
      .where(and(eq(recommendationRuns.userId, userPayload.id), eq(recommendationRuns.isActive, true)))
      .orderBy(desc(recommendationRuns.createdAt));

    if (!run) {
      return reply.status(404).send({
        success: false,
        error: { code: 'RESOURCE_NOT_FOUND', message: 'No active recommendation run found to activate' },
      });
    }

    const plan = run.generatedPlan as { schedule: Array<{ day: string; type: string; activity: string; durationMinutes: number }> };
    const now = new Date();
    const createdSessions = [];

    for (let i = 0; i < 7; i++) {
      const scheduledDate = new Date(now);
      scheduledDate.setDate(now.getDate() + i);
      const dayName = scheduledDate.toLocaleDateString('en-US', { weekday: 'long' });

      const dayPlan = plan.schedule.find((s) => s.day === dayName);
      if (dayPlan && dayPlan.type === 'workout') {
        const [session] = await db
          .insert(workoutSessions)
          .values({
            userId: userPayload.id,
            title: `${dayPlan.activity} Session`,
            scheduledDate: scheduledDate.toISOString().split('T')[0],
            status: 'scheduled',
          })
          .returning();
        createdSessions.push(session);
      }
    }

    return reply.send({
      success: true,
      data: {
        message: 'Fitness blueprint activated and workouts scheduled',
        scheduledCount: createdSessions.length,
        sessions: createdSessions,
      },
    });
  });

  // Accept Blueprint and Activate Weekly Workouts (FR-010)
  fastify.post('/:id/accept', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Recommendations & Blueprint Engine'],
      summary: 'Accept blueprint by ID and schedule workouts',
      description: 'Activates the recommendation run by ID and creates scheduled workout sessions in the calendar.',
      security: [{ bearerAuth: [] }],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid', description: 'Recommendation run ID', example: 'abc2fa65-dfb7-46e0-8cad-b7eed969fc71' },
        },
      },
      response: {
        200: {
          type: 'object',
          description: 'Confirmation and scheduled session records',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                message: { type: 'string', example: 'Fitness blueprint accepted and workouts scheduled' },
                scheduledCount: { type: 'integer', example: 3 },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                message: 'Fitness blueprint accepted and workouts scheduled',
                scheduledCount: 3,
                sessions: [
                  { id: '11111111-2222-3333-4444-555555555555', title: 'Bodyweight Resistance Circuit Session', scheduledDate: '2026-11-09', status: 'scheduled' },
                  { id: '22222222-3333-4444-5555-666666666666', title: 'Bodyweight Resistance Circuit Session', scheduledDate: '2026-11-11', status: 'scheduled' },
                  { id: '33333333-4444-5555-6666-777777777777', title: 'Brisk Walking Session', scheduledDate: '2026-11-13', status: 'scheduled' },
                ],
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const userPayload = request.user as { id: string };

    const [run] = await db
      .select()
      .from(recommendationRuns)
      .where(and(eq(recommendationRuns.id, id), eq(recommendationRuns.userId, userPayload.id)));

    if (!run) {
      return reply.status(404).send({
        success: false,
        error: { code: 'RESOURCE_NOT_FOUND', message: 'Recommendation run not found' },
      });
    }

    const plan = run.generatedPlan as { schedule: Array<{ day: string; type: string; activity: string; durationMinutes: number }> };
    
    // Schedule sessions for the current week starting from today
    const now = new Date();
    const createdSessions = [];

    for (let i = 0; i < 7; i++) {
      const scheduledDate = new Date(now);
      scheduledDate.setDate(now.getDate() + i);
      const dayName = scheduledDate.toLocaleDateString('en-US', { weekday: 'long' });

      const dayPlan = plan.schedule.find((s) => s.day === dayName);
      if (dayPlan && dayPlan.type === 'workout') {
        const [session] = await db
          .insert(workoutSessions)
          .values({
            userId: userPayload.id,
            title: `${dayPlan.activity} Session`,
            scheduledDate: scheduledDate.toISOString().split('T')[0],
            status: 'scheduled',
          })
          .returning();
        createdSessions.push(session);
      }
    }

    return reply.send({
      success: true,
      data: {
        message: 'Fitness blueprint accepted and workouts scheduled',
        scheduledCount: createdSessions.length,
        sessions: createdSessions,
      },
    });
  });
}

