import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { buildApp } from '../app.js';
import { FastifyInstance } from 'fastify';
import { client } from '../db/index.js';

describe('End-to-End User Journeys (Journeys 1 to 6)', () => {
  let app: FastifyInstance;
  let userToken: string;
  let userId: string;
  let assessmentId: string;
  let runId: string;
  let sessionId: string;
  let foodId: string;
  let portionUnitId: string;

  beforeAll(async () => {
    app = buildApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
    await client.end();
  });

  it('Journey 1: User Onboarding -> Assessment -> 6-D Classification -> Blueprint Activation', async () => {
    // 1. Register User
    const regRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: `journey_athlete_${Date.now()}@example.com`,
        password: 'Password123!',
        firstName: 'Folake',
        lastName: 'Adeyemi',
        dateOfBirth: '1998-04-12',
        biologicalSex: 'female',
        countryCode: 'NG',
        unitSystem: 'metric',
        consentTerms: true,
        consentHealthData: true,
      },
    });

    expect(regRes.statusCode).toBe(201);
    const regData = regRes.json();
    userToken = regData.data.token;
    userId = regData.data.user.id;

    // 2. Start Assessment
    const startAssessRes = await app.inject({
      method: 'POST',
      url: '/api/v1/assessments',
      headers: { authorization: `Bearer ${userToken}` },
    });
    expect(startAssessRes.statusCode).toBe(201);
    assessmentId = startAssessRes.json().data.id;

    // 3. Auto-save Stages A through F
    const saveRes = await app.inject({
      method: 'PUT',
      url: `/api/v1/assessments/${assessmentId}/responses`,
      headers: { authorization: `Bearer ${userToken}` },
      payload: {
        stage: 'STAGE_F',
        responses: {
          A01: '1998-04-12',
          A02: 'female',
          A03: 168,
          A04: 64,
          B01: 'weight_management',
          C01: 'beginner',
          C02: 'never',
          C05: 'some_movement',
          D01: '3',
          D02: '30_45',
          D03: 'home',
          D04: ['none'],
          E01: 'no',
          E05: 'no', // Cleared cardiac safety
          F01: ['health', 'appearance'],
          F05: 'building_consistency',
        },
      },
    });
    expect(saveRes.statusCode).toBe(200);

    // 4. Complete Assessment
    const completeRes = await app.inject({
      method: 'POST',
      url: `/api/v1/assessments/${assessmentId}/complete`,
      headers: { authorization: `Bearer ${userToken}` },
    });
    expect(completeRes.statusCode).toBe(200);
    const completeData = completeRes.json();
    expect(completeData.data.classification.primaryGoal).toBe('weight_management');
    expect(completeData.data.classification.safetyStatus).toBe('standard');
    expect(completeData.data.nutrition.bmr).toBeGreaterThan(1200);
    expect(completeData.data.nutrition.targetDailyCalories).toBeGreaterThan(1200);

    // 5. Generate Blueprint
    const recRes = await app.inject({
      method: 'POST',
      url: '/api/v1/recommendations/generate',
      headers: { authorization: `Bearer ${userToken}` },
    });
    expect(recRes.statusCode).toBe(201);
    const recData = recRes.json();
    runId = recData.data.runId;
    expect(recData.data.blueprint.schedule).toHaveLength(7);

    // 6. Accept Blueprint & Activate Workouts
    const acceptRes = await app.inject({
      method: 'POST',
      url: `/api/v1/recommendations/${runId}/accept`,
      headers: { authorization: `Bearer ${userToken}` },
    });
    expect(acceptRes.statusCode).toBe(200);
    expect(acceptRes.json().data.scheduledCount).toBeGreaterThan(0);
  });

  it('Journey 2: Live Workout Execution, Set Logging & PR Detection', async () => {
    // 1. Start Workout Session
    const startRes = await app.inject({
      method: 'POST',
      url: '/api/v1/workouts/sessions',
      headers: { authorization: `Bearer ${userToken}` },
      payload: { title: 'Full Body Circuit A' },
    });
    expect(startRes.statusCode).toBe(201);
    sessionId = startRes.json().data.id;

    // Fetch an exercise
    const exRes = await app.inject({ method: 'GET', url: '/api/v1/workouts/exercises' });
    const exId = exRes.json().data[0].id;

    // 2. Log Set 1 (Air Squats 15 reps, 0kg)
    const set1Res = await app.inject({
      method: 'POST',
      url: `/api/v1/workouts/sessions/${sessionId}/sets`,
      headers: { authorization: `Bearer ${userToken}` },
      payload: {
        exerciseId: exId,
        setOrder: 1,
        reps: 15,
        weightKg: 0,
      },
    });
    expect(set1Res.statusCode).toBe(201);

    // 3. Log Set 2 with weight (Goblet Squats 10 reps, 16kg) -> Detects PR!
    const set2Res = await app.inject({
      method: 'POST',
      url: `/api/v1/workouts/sessions/${sessionId}/sets`,
      headers: { authorization: `Bearer ${userToken}` },
      payload: {
        exerciseId: exId,
        setOrder: 2,
        reps: 10,
        weightKg: 16,
      },
    });
    expect(set2Res.statusCode).toBe(201);
    expect(set2Res.json().data.isPersonalRecord).toBe(true);

    // 4. Complete Workout Session
    const completeRes = await app.inject({
      method: 'POST',
      url: `/api/v1/workouts/sessions/${sessionId}/complete`,
      headers: { authorization: `Bearer ${userToken}` },
      payload: { rpe: 7, durationSeconds: 1800 },
    });
    expect(completeRes.statusCode).toBe(200);
    const completeData = completeRes.json();
    expect(completeData.data.totalVolumeKg).toBe(160); // 10 reps * 16kg
  });

  it('Journey 3: Outdoor GPS Activity Tracking with Privacy Masking', async () => {
    // 1. Set user privacy zone around home (Lekki, Lagos)
    await app.inject({
      method: 'POST',
      url: '/api/v1/activities/privacy-zones',
      headers: { authorization: `Bearer ${userToken}` },
      payload: {
        label: 'Home',
        centerLatitude: 6.4474,
        centerLongitude: 3.4723,
        radiusMeters: 250,
      },
    });

    // 2. Start GPS run
    const startRunRes = await app.inject({
      method: 'POST',
      url: '/api/v1/activities/gps/start',
      headers: { authorization: `Bearer ${userToken}` },
      payload: { activityType: 'running' },
    });
    expect(startRunRes.statusCode).toBe(201);
    const actId = startRunRes.json().data.id;

    // 3. Complete run with points inside and outside privacy zone
    const completeRunRes = await app.inject({
      method: 'POST',
      url: '/api/v1/activities/gps/complete',
      headers: { authorization: `Bearer ${userToken}` },
      payload: {
        activityId: actId,
        durationSeconds: 1200,
        distanceMeters: 3200,
        averagePaceSecPerKm: 375,
        polylineEncoded: '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
        rawGpsPoints: [
          { lat: 6.44741, lng: 3.47231 }, // inside home privacy buffer -> masked out
          { lat: 6.45500, lng: 3.48000 }, // outside -> retained
        ],
      },
    });
    expect(completeRunRes.statusCode).toBe(200);
    const runData = completeRunRes.json().data;
    expect(runData.privacyMaskApplied).toBe(true);
    expect(runData.clippedGpsPointsCount).toBe(1);
  });

  it('Journey 4: Nutrition Food Search & Logging with Nigerian Portion Units', async () => {
    // 1. Search for food
    const searchRes = await app.inject({
      method: 'GET',
      url: '/api/v1/nutrition/foods/search?query=pounded',
    });
    expect(searchRes.statusCode).toBe(200);
    const food = searchRes.json().data[0];
    foodId = food.id;
    portionUnitId = food.portionUnits[0]?.id; // e.g. wrap (200g)

    // 2. Log 1 wrap of Pounded Yam
    const logRes = await app.inject({
      method: 'POST',
      url: '/api/v1/nutrition/entries',
      headers: { authorization: `Bearer ${userToken}` },
      payload: {
        foodId,
        mealSlot: 'lunch',
        quantity: 1,
        portionUnitId,
      },
    });
    expect(logRes.statusCode).toBe(201);
    expect(logRes.json().data.totalCalories).toBeDefined();

    // 3. Verify Daily Nutrition Summary
    const summaryRes = await app.inject({
      method: 'GET',
      url: '/api/v1/nutrition/summary',
      headers: { authorization: `Bearer ${userToken}` },
    });
    expect(summaryRes.statusCode).toBe(200);
    const summaryData = summaryRes.json().data;
    expect(summaryData.totals.calories).toBeGreaterThan(0);
    expect(summaryData.meals.lunch).toHaveLength(1);
  });

  it('Journey 5: Batch Offline Sync with Idempotency & Quarantine', async () => {
    const idempotencyKey = `idemp_${Date.now()}`;

    const batchRes = await app.inject({
      method: 'POST',
      url: '/api/v1/sync/batch',
      headers: {
        authorization: `Bearer ${userToken}` },
      payload: {
        mutations: [
          {
            id: 'mut_1',
            type: 'log_set',
            payload: {
              sessionId,
              exerciseId: '00000000-0000-0000-0000-000000000000', // Non-existent foreign key -> will be quarantined!
              reps: 10,
              weightKg: 20,
            },
            clientTimestamp: new Date().toISOString(),
          },
        ],
      },
    });

    // Header missing test
    expect(batchRes.statusCode).toBe(400);

    // Provide mandatory Idempotency-Key header
    const validBatchRes = await app.inject({
      method: 'POST',
      url: '/api/v1/sync/batch',
      headers: {
        authorization: `Bearer ${userToken}`,
        'idempotency-key': idempotencyKey,
      },
      payload: {
        mutations: [
          {
            id: 'poison_pill_mut',
            type: 'log_set',
            payload: {
              sessionId,
              exerciseId: '00000000-0000-0000-0000-000000000000', // invalid exerciseId
              reps: 10,
              weightKg: 20,
            },
            clientTimestamp: new Date().toISOString(),
          },
        ],
      },
    });

    expect(validBatchRes.statusCode).toBe(200);
    const batchData = validBatchRes.json().data;
    expect(batchData.quarantinedCount).toBe(1);
    expect(batchData.quarantinedIds).toContain('poison_pill_mut');

    // Test Idempotent Replay: sending same idempotency key returns cached response
    const replayRes = await app.inject({
      method: 'POST',
      url: '/api/v1/sync/batch',
      headers: {
        authorization: `Bearer ${userToken}`,
        'idempotency-key': idempotencyKey,
      },
      payload: { mutations: [] },
    });
    expect(replayRes.statusCode).toBe(200);
    expect(replayRes.json().data.quarantinedCount).toBe(1);
  });

  it('Journey 6: Safety Circuit Breaker Lock when E05 chest pain symptom reported', async () => {
    // 1. Register new user who reports chest pain
    const userRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: `cardiac_patient_${Date.now()}@example.com`,
        password: 'Password123!',
        dateOfBirth: '1985-03-22',
        consentTerms: true,
        consentHealthData: true,
      },
    });
    const cardiacToken = userRes.json().data.token;

    // 2. Start Assessment
    const startRes = await app.inject({
      method: 'POST',
      url: '/api/v1/assessments',
      headers: { authorization: `Bearer ${cardiacToken}` },
    });
    const cardiacAssessId = startRes.json().data.id;

    // 3. Answer Stage E E05 with "yes" (chest pain symptom during exercise)
    await app.inject({
      method: 'PUT',
      url: `/api/v1/assessments/${cardiacAssessId}/responses`,
      headers: { authorization: `Bearer ${cardiacToken}` },
      payload: {
        stage: 'STAGE_E',
        responses: {
          E05: 'yes',
        },
      },
    });

    // 4. Complete Assessment
    const completeRes = await app.inject({
      method: 'POST',
      url: `/api/v1/assessments/${cardiacAssessId}/complete`,
      headers: { authorization: `Bearer ${cardiacToken}` },
    });
    expect(completeRes.statusCode).toBe(200);
    const completeData = completeRes.json().data;
    expect(completeData.isCriticalStop).toBe(true);
    expect(completeData.safetyDisclaimer).toContain('URGENT: Exercise recommendations are paused');

    // 5. Attempt to generate recommendations -> Must be blocked with 403 Forbidden!
    const recRes = await app.inject({
      method: 'POST',
      url: '/api/v1/recommendations/generate',
      headers: { authorization: `Bearer ${cardiacToken}` },
    });
    expect(recRes.statusCode).toBe(403);
    expect(recRes.json().error.code).toBe('SAFETY_INTERCEPT_ACTIVE');
  });

  it('Unified Home Dashboard returns aggregated daily summary', async () => {
    const dashRes = await app.inject({
      method: 'GET',
      url: '/api/v1/dashboard/daily-summary',
      headers: { authorization: `Bearer ${userToken}` },
    });

    expect(dashRes.statusCode).toBe(200);
    const data = dashRes.json().data;
    expect(data.greeting).toContain('Folake');
    expect(data.primaryGoal).toBe('weight_management');
    expect(data.nutrition.consumedCalories).toBeGreaterThan(0);
    expect(data.recentWorkouts.length).toBeGreaterThan(0);
  });
});

