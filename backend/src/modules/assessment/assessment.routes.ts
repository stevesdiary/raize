import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../../db/index.js';
import {
  assessmentQuestions,
  assessmentOptions,
  fitnessAssessments,
  assessmentResponses,
  fitnessProfiles,
  fitnessGoals,
  healthRestrictions,
  userProfiles,
  users,
} from '../../db/schema/index.js';
import { eq, asc, desc, and } from 'drizzle-orm';
import { calculateAge, calculateBMR, calculateTDEE, calculateTargetCalories } from '../../utils/calculator.js';
import { encryptSensitiveField } from '../../utils/security.js';
import { sendCardiacSafetyAlertEmail } from '../../services/email.service.js';

export async function assessmentRoutes(fastify: FastifyInstance) {
  // Get all active questions grouped by stage
  fastify.get('/questions', {
    schema: {
      tags: ['Assessments & PAR-Q Safety'],
      summary: 'List standardized Stage A-F questionnaire',
      description: 'Returns the full clinical, athletic, and biometric questionnaire with option trees and cardiac safety checks (E05).',
      response: {
        200: {
          type: 'object',
          description: 'Standardized assessment questionnaire array',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  id: { type: 'string', example: 'B01' },
                  stage: { type: 'string', example: 'STAGE_B' },
                  section: { type: 'string', example: 'Primary Fitness Goals' },
                  questionText: { type: 'string', example: 'What is your primary fitness goal?' },
                  inputType: { type: 'string', example: 'single_choice' },
                  isRequired: { type: 'boolean', example: true },
                  options: {
                    type: 'array',
                    items: {
                      type: 'object',
                      properties: {
                        id: { type: 'string', example: 'opt_b01_1' },
                        optionValue: { type: 'string', example: 'weight_management' },
                        displayText: { type: 'string', example: 'Weight Management / Fat Loss' },
                      },
                    },
                  },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: [
                {
                  id: 'B01',
                  stage: 'STAGE_B',
                  section: 'Primary Fitness Goals',
                  questionText: 'What is your primary fitness goal?',
                  inputType: 'single_choice',
                  isRequired: true,
                  options: [
                    { id: 'opt_b01_1', optionValue: 'weight_management', displayText: 'Weight Management / Fat Loss' },
                    { id: 'opt_b01_2', optionValue: 'hypertrophy', displayText: 'Muscle Hypertrophy / Bodybuilding' },
                    { id: 'opt_b01_3', optionValue: 'cardiovascular_health', displayText: 'Cardiovascular Conditioning / Stamina' },
                  ],
                },
                {
                  id: 'E05',
                  stage: 'STAGE_E',
                  section: 'Health & Safety Screen (PAR-Q)',
                  questionText: 'Do you experience chest pain, dizziness, or loss of balance during physical exertion?',
                  inputType: 'single_choice',
                  isRequired: true,
                  options: [
                    { id: 'opt_e05_1', optionValue: 'no', displayText: 'No, never' },
                    { id: 'opt_e05_2', optionValue: 'yes', displayText: 'Yes (Requires medical review)' },
                  ],
                },
              ],
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const questionsList = await db
      .select()
      .from(assessmentQuestions)
      .where(eq(assessmentQuestions.isActive, true))
      .orderBy(asc(assessmentQuestions.displayOrder));

    const optionsList = await db
      .select()
      .from(assessmentOptions)
      .orderBy(asc(assessmentOptions.displayOrder));

    const optionsMap = new Map<string, typeof optionsList>();
    for (const opt of optionsList) {
      if (!optionsMap.has(opt.questionId)) {
        optionsMap.set(opt.questionId, []);
      }
      optionsMap.get(opt.questionId)?.push(opt);
    }

    const payload = questionsList.map((q) => {
      const opts = optionsMap.get(q.id) || [];
      return {
        ...q,
        options: opts.map((o) => ({
          ...o,
          label: o.displayText,
        })),
      };
    });

    return reply.send({ success: true, data: payload });
  });

  // Start new assessment or get draft (FR-003, FR-004)
  fastify.post('/', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Assessments & PAR-Q Safety'],
      summary: 'Start new assessment or retrieve draft in-progress session',
      description: 'Creates a new versioned fitness assessment or returns the currently active in-progress draft.',
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          description: 'Existing in-progress assessment draft',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: 'fa836747-dbeb-4b27-9a88-e1c3011da315' },
                version: { type: 'integer', example: 1 },
                status: { type: 'string', example: 'in_progress' },
                lastActiveStage: { type: 'string', example: 'STAGE_A' },
                responses: { type: 'object', example: { A01: '1998-05-14' } },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: 'fa836747-dbeb-4b27-9a88-e1c3011da315',
                version: 1,
                status: 'in_progress',
                lastActiveStage: 'STAGE_B',
                responses: {
                  B01: 'weight_management',
                  B02: 'lose_fat',
                  C01: 'intermediate',
                },
              },
            },
          ],
        },
        201: {
          type: 'object',
          description: 'Newly initialized assessment',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: 'fa836747-dbeb-4b27-9a88-e1c3011da315' },
                version: { type: 'integer', example: 1 },
                status: { type: 'string', example: 'in_progress' },
                lastActiveStage: { type: 'string', example: 'STAGE_A' },
                responses: { type: 'object', example: {} },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: 'fa836747-dbeb-4b27-9a88-e1c3011da315',
                version: 1,
                status: 'in_progress',
                lastActiveStage: 'STAGE_A',
                responses: {},
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };

    // Query user profile to pre-fill verified account data (DOB & measurement preference)
    const [profile] = await db.select().from(userProfiles).where(eq(userProfiles.userId, userPayload.id));
    const prefilledResponses: Record<string, any> = {
      ...(profile?.dateOfBirth ? { A01: profile.dateOfBirth } : {}),
      ...(profile?.unitSystem ? { A06: profile.unitSystem } : {}),
    };

    // Check existing in_progress assessment
    const [draft] = await db
      .select()
      .from(fitnessAssessments)
      .where(and(eq(fitnessAssessments.userId, userPayload.id), eq(fitnessAssessments.status, 'in_progress')))
      .orderBy(desc(fitnessAssessments.version));

    if (draft) {
      const mergedDraftResponses = {
        ...prefilledResponses,
        ...((draft.responses as Record<string, any>) || {}),
      };
      return reply.send({ success: true, data: { ...draft, responses: mergedDraftResponses } });
    }

    // Determine version number
    const [lastCompleted] = await db
      .select()
      .from(fitnessAssessments)
      .where(eq(fitnessAssessments.userId, userPayload.id))
      .orderBy(desc(fitnessAssessments.version));

    const newVersion = lastCompleted ? lastCompleted.version + 1 : 1;

    const [newAssessment] = await db
      .insert(fitnessAssessments)
      .values({
        userId: userPayload.id,
        version: newVersion,
        status: 'in_progress',
        lastActiveStage: 'STAGE_A',
        responses: prefilledResponses,
      })
      .returning();

    return reply.status(201).send({ success: true, data: newAssessment });
  });

  // Auto-save question responses (FR-004)
  fastify.put('/:id/responses', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Assessments & PAR-Q Safety'],
      summary: 'Auto-save stage responses',
      description: 'Merges question answers into the assessment response state as the athlete progresses through stages.',
      security: [{ bearerAuth: [] }],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid', description: 'Assessment session ID', example: 'fa836747-dbeb-4b27-9a88-e1c3011da315' },
        },
      },
      body: {
        type: 'object',
        required: ['stage', 'responses'],
        properties: {
          stage: { type: 'string', enum: ['STAGE_A', 'STAGE_B', 'STAGE_C', 'STAGE_D', 'STAGE_E', 'STAGE_F'], example: 'STAGE_B' },
          responses: {
            type: 'object',
            description: 'Key-value map of question IDs and answers',
            example: {
              B01: 'weight_management',
              B02: 'lose_fat',
              C01: 'intermediate',
              D01: '3',
              E05: 'no',
            },
          },
        },
        examples: [
          {
            stage: 'STAGE_B',
            responses: {
              B01: 'weight_management',
              B02: 'lose_fat',
              C01: 'intermediate',
              D01: '3',
              E05: 'no',
            },
          },
        ],
      },
      response: {
        200: {
          type: 'object',
          description: 'Updated assessment responses',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: 'fa836747-dbeb-4b27-9a88-e1c3011da315' },
                lastActiveStage: { type: 'string', example: 'STAGE_B' },
                responses: { type: 'object', example: { B01: 'weight_management', C01: 'intermediate' } },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: 'fa836747-dbeb-4b27-9a88-e1c3011da315',
                lastActiveStage: 'STAGE_B',
                responses: {
                  B01: 'weight_management',
                  B02: 'lose_fat',
                  C01: 'intermediate',
                  D01: '3',
                  E05: 'no',
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
      stage: string;
      responses: Record<string, any>; // { "A01": "1995-05-12", "B01": "weight_management" }
    };

    const [assessment] = await db
      .select()
      .from(fitnessAssessments)
      .where(and(eq(fitnessAssessments.id, id), eq(fitnessAssessments.userId, userPayload.id)));

    if (!assessment) {
      return reply.status(404).send({
        success: false,
        error: { code: 'RESOURCE_NOT_FOUND', message: 'Assessment not found' },
      });
    }

    if (assessment.status === 'completed') {
      return reply.status(400).send({
        success: false,
        error: { code: 'ASSESSMENT_ALREADY_COMPLETED', message: 'Completed assessments are immutable' },
      });
    }

    // Merge responses into JSON state
    const currentResponses = (assessment.responses as Record<string, any>) || {};
    const updatedResponses = { ...currentResponses, ...body.responses };

    await db
      .update(fitnessAssessments)
      .set({
        responses: updatedResponses,
        lastActiveStage: body.stage || assessment.lastActiveStage,
      })
      .where(eq(fitnessAssessments.id, id));

    return reply.send({
      success: true,
      data: {
        id,
        lastActiveStage: body.stage || assessment.lastActiveStage,
        responses: updatedResponses,
      },
    });
  });

  // Complete Assessment & Run 6-Dimension Classification (FR-005, FR-006, FR-007)
  fastify.post('/:id/complete', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Assessments & PAR-Q Safety'],
      summary: 'Complete assessment, evaluate PAR-Q safety & compute Mifflin-St Jeor TDEE',
      description:
        'Finalizes the assessment. Evaluates Stage E PAR-Q cardiac safety circuit breaker (E05). Computes BMR, TDEE, target daily caloric deficit/surplus, and 6-D athletic classification.',
      security: [{ bearerAuth: [] }],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid', description: 'Assessment session ID', example: 'fa836747-dbeb-4b27-9a88-e1c3011da315' },
        },
      },
      response: {
        200: {
          type: 'object',
          description: '6-D athletic classification & caloric budget summary',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                assessmentId: { type: 'string', format: 'uuid', example: 'fa836747-dbeb-4b27-9a88-e1c3011da315' },
                classification: {
                  type: 'object',
                  properties: {
                    primaryGoal: { type: 'string', example: 'weight_management' },
                    experience: { type: 'string', example: 'intermediate' },
                    activityBaseline: { type: 'string', example: 'low_active' },
                    trainingEnvironment: { type: 'string', example: 'home' },
                    availabilityLevel: { type: 'string', example: 'moderate' },
                    safetyStatus: { type: 'string', example: 'standard' },
                  },
                },
                nutrition: {
                  type: 'object',
                  properties: {
                    bmr: { type: 'number', example: 1576 },
                    tdee: { type: 'number', example: 2167 },
                    targetDailyCalories: { type: 'number', example: 1667 },
                  },
                },
                isCriticalStop: { type: 'boolean', example: false },
                safetyDisclaimer: { type: 'string', nullable: true, example: null },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                assessmentId: 'fa836747-dbeb-4b27-9a88-e1c3011da315',
                classification: {
                  primaryGoal: 'weight_management',
                  experience: 'intermediate',
                  activityBaseline: 'low_active',
                  trainingEnvironment: 'home',
                  availabilityLevel: 'moderate',
                  safetyStatus: 'standard',
                },
                nutrition: {
                  bmr: 1576,
                  tdee: 2167,
                  targetDailyCalories: 1667,
                },
                isCriticalStop: false,
                safetyDisclaimer: null,
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const userPayload = request.user as { id: string };

    const [assessment] = await db
      .select()
      .from(fitnessAssessments)
      .where(and(eq(fitnessAssessments.id, id), eq(fitnessAssessments.userId, userPayload.id)));

    if (!assessment) {
      return reply.status(404).send({
        success: false,
        error: { code: 'RESOURCE_NOT_FOUND', message: 'Assessment not found' },
      });
    }

    const responses = (assessment.responses as Record<string, any>) || {};

    // Retrieve user profile to compute age & biometrics
    const [profile] = await db.select().from(userProfiles).where(eq(userProfiles.userId, userPayload.id));
    const age = profile ? calculateAge(profile.dateOfBirth) : 25;
    const weightKg = profile?.weightKg ? parseFloat(profile.weightKg) : 70;
    const heightCm = profile?.heightCm ? parseFloat(profile.heightCm) : 175;
    const sex = profile?.biologicalSex || 'prefer_not_to_say';

    // 1. SAFETY GATE: Check E05 (Cardiac symptoms: chest pain, fainting, shortness of breath)
    const e05Response = responses['E05'];
    const hasCriticalCardiacSymptom = e05Response === 'yes' || e05Response === 'prefer_not_to_say';

    let safetyStatus = 'standard';
    if (hasCriticalCardiacSymptom) {
      safetyStatus = 'exercise_paused_pending_assessment';
    } else if (responses['E01'] === 'yes' || responses['E02'] === 'yes' || responses['E04'] === 'yes') {
      safetyStatus = 'needs_modification';
    }

    // Save Health Restrictions if flagged
    if (responses['E01'] === 'yes' || hasCriticalCardiacSymptom) {
      await db.insert(healthRestrictions).values({
        userId: userPayload.id,
        restrictionType: hasCriticalCardiacSymptom ? 'chest_pain_e05' : 'joint_or_movement_limitation',
        affectedBodyParts: responses['E01_affected'] ? [responses['E01_affected']] : [],
        isCriticalStop: hasCriticalCardiacSymptom,
        encryptedNotes: responses['E06'] ? await encryptSensitiveField(responses['E06']) : null,
      });

      if (hasCriticalCardiacSymptom) {
        const [u] = await db.select().from(users).where(eq(users.id, userPayload.id));
        if (u) {
          sendCardiacSafetyAlertEmail(u.email, profile?.firstName || '').catch((err) => {
            request.log.error(err, 'Failed to dispatch SendByte cardiac safety alert');
          });
        }
      }
    }

    // 2. PRIMARY GOAL & EXPERIENCE CLASSIFICATION
    const primaryGoal = responses['B01'] || 'weight_management';
    const experience = responses['C01'] || 'beginner';
    const baseline = responses['C05'] || 'low_active';
    const environment = responses['D03'] || 'home';
    const weeklyDaysRaw = responses['D01'] || '3';
    const availabilityLevel = weeklyDaysRaw === '1_2' ? 'low' : weeklyDaysRaw === '3' ? 'moderate' : 'high';

    // 3. CALORIC BUDGETS (Mifflin-St Jeor) & STEP TARGET
    const bmr = calculateBMR(weightKg, heightCm, age, sex);
    const tdee = calculateTDEE(bmr, baseline);
    const targetCalories = calculateTargetCalories(tdee, primaryGoal, age, sex);
    const baselineStepTargets: Record<string, number> = {
      sedentary: 6000,
      low_active: 8000,
      moderately_active: 10000,
      highly_active: 12500,
    };
    const targetDailySteps = baselineStepTargets[baseline] || 10000;

    // Update / Insert Fitness Profile
    await db
      .insert(fitnessProfiles)
      .values({
        userId: userPayload.id,
        primaryGoal,
        experience,
        activityBaseline: baseline,
        trainingEnvironment: environment,
        availabilityLevel,
        safetyStatus,
        classificationBadge: `${experience.toUpperCase()}_${primaryGoal.toUpperCase()}`,
        bmrCalories: bmr,
        tdeeCalories: tdee,
        targetDailyCalories: targetCalories,
        targetDailySteps,
      })
      .onConflictDoUpdate({
        target: fitnessProfiles.userId,
        set: {
          primaryGoal,
          experience,
          activityBaseline: baseline,
          trainingEnvironment: environment,
          availabilityLevel,
          safetyStatus,
          classificationBadge: `${experience.toUpperCase()}_${primaryGoal.toUpperCase()}`,
          bmrCalories: bmr,
          tdeeCalories: tdee,
          targetDailyCalories: targetCalories,
          targetDailySteps,
          lastCalculatedAt: new Date(),
          updatedAt: new Date(),
        },
      });

    // Save Primary Goal in fitness_goals
    await db.insert(fitnessGoals).values({
      userId: userPayload.id,
      goalType: primaryGoal,
      priority: 'primary',
      status: 'active',
      strategyNotes: responses['B03'] || 'Generated from comprehensive Stage B assessment',
    });

    // Mark assessment completed
    await db
      .update(fitnessAssessments)
      .set({
        status: 'completed',
        completedAt: new Date(),
      })
      .where(eq(fitnessAssessments.id, id));

    return reply.send({
      success: true,
      data: {
        assessmentId: id,
        classification: {
          primaryGoal,
          experience,
          activityBaseline: baseline,
          trainingEnvironment: environment,
          availabilityLevel,
          safetyStatus,
        },
        nutrition: {
          bmr,
          tdee,
          targetDailyCalories: targetCalories,
        },
        isCriticalStop: hasCriticalCardiacSymptom,
        safetyDisclaimer: hasCriticalCardiacSymptom
          ? 'URGENT: Exercise recommendations are paused. You reported symptoms such as chest pain or fainting during exercise. Please seek medical evaluation from a healthcare professional before engaging in physical training.'
          : null,
      },
    });
  });
}

