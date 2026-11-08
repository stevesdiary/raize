import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { buildApp } from '../app.js';
import { FastifyInstance } from 'fastify';
import { client } from '../db/index.js';

describe('Fastify API Integration Endpoints', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = buildApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
    await client.end();
  });

  it('GET /health returns healthy status', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/health',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.status).toBe('healthy');
    expect(body.service).toBe('raize-fitness-backend');
  });

  it('POST /api/v1/auth/register rejects minors under 18 years old', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: 'minor@example.com',
        password: 'Password123!',
        dateOfBirth: '2015-05-10', // ~11 years old
        consentTerms: true,
        consentHealthData: true,
      },
    });

    expect(res.statusCode).toBe(400);
    const body = res.json();
    expect(body.success).toBe(false);
    expect(body.error.code).toBe('UNDERAGE_NOT_PERMITTED');
  });

  it('POST /api/v1/auth/register creates user and hashes password with Argon2id', async () => {
    const uniqueEmail = `athlete_${Date.now()}@example.com`;
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: uniqueEmail,
        password: 'SecurePassword2026!',
        firstName: 'Chidi',
        lastName: 'Okonkwo',
        dateOfBirth: '1996-08-20',
        countryCode: 'NG',
        unitSystem: 'metric',
        consentTerms: true,
        consentHealthData: true,
      },
    });

    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.user.email).toBe(uniqueEmail);
    expect(body.data.token).toBeDefined();

    // Verify Login with Email
    const loginRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: {
        email: uniqueEmail,
        password: 'SecurePassword2026!',
      },
    });

    expect(loginRes.statusCode).toBe(200);
    const loginBody = loginRes.json();
    expect(loginBody.data.token).toBeDefined();
    expect(loginBody.data.user.profile.firstName).toBe('Chidi');
    expect(loginBody.data.user.username).toBeDefined();
  });

  it('supports unique username registration, duplicate rejection, and username login', async () => {
    const timestamp = Date.now();
    const uniqueUsername = `athlete_${timestamp}`;
    const uniqueEmail = `handle_${timestamp}@example.com`;
    const password = 'HandlePassword123!';

    // 1. Register with username
    const regRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: uniqueEmail,
        username: uniqueUsername,
        password,
        firstName: 'Tunde',
        lastName: 'Bakare',
        dateOfBirth: '1995-04-12',
        consentTerms: true,
        consentHealthData: true,
      },
    });

    expect(regRes.statusCode).toBe(201);
    const regBody = regRes.json();
    expect(regBody.data.user.username).toBe(uniqueUsername);

    // 2. Reject duplicate username
    const dupRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: `different_${timestamp}@example.com`,
        username: uniqueUsername, // Duplicate!
        password,
        dateOfBirth: '1995-04-12',
        consentTerms: true,
        consentHealthData: true,
      },
    });
    expect(dupRes.statusCode).toBe(409);
    expect(dupRes.json().error.code).toBe('USERNAME_ALREADY_EXISTS');

    // 3. Login using username as identifier
    const loginUsernameRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: {
        identifier: uniqueUsername,
        password,
      },
    });
    expect(loginUsernameRes.statusCode).toBe(200);
    expect(loginUsernameRes.json().data.user.username).toBe(uniqueUsername);

    // 4. Login using @username format
    const loginAtUsernameRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: {
        identifier: `@${uniqueUsername}`,
        password,
      },
    });
    expect(loginAtUsernameRes.statusCode).toBe(200);

    // 5. Leaderboard lists athletes with usernames
    const lbRes = await app.inject({
      method: 'GET',
      url: '/api/v1/community/leaderboard',
    });
    expect(lbRes.statusCode).toBe(200);
    const lbBody = lbRes.json();
    expect(lbBody.success).toBe(true);
    expect(Array.isArray(lbBody.data)).toBe(true);
    expect(lbBody.data.length).toBeGreaterThan(0);
    expect(lbBody.data[0].handle).toMatch(/^@/);
  });

  it('GET /api/v1/assessments/questions returns standardized A01-F05 questionnaire', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/assessments/questions',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.length).toBeGreaterThanOrEqual(25);

    // Verify Stage E E05 is present
    const e05 = body.data.find((q: any) => q.id === 'E05');
    expect(e05).toBeDefined();
    expect(e05.questionText).toContain('chest pain');
  });

  it('GET /api/v1/nutrition/foods/search returns Nigerian foods with colloquial portions', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/nutrition/foods/search?query=jollof',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.length).toBeGreaterThan(0);
    expect(body.data[0].name).toContain('Jollof Rice');
    expect(body.data[0].isVerifiedNigerian).toBe(true);
    expect(body.data[0].portionUnits.length).toBeGreaterThan(0);
  });

  it('GET /api/v1/workouts/exercises/:slug/media returns 3D human biomechanical animation and R2 object storage links', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/workouts/exercises/barbell-bench-press/media',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.exerciseSlug).toBe('barbell-bench-press');
    expect(body.data.animation3dGlbUrl).toContain('https://media.raize.fit/exercises/3d/barbell-bench-press-human-3d.glb');
    expect(body.data.animation3dUsdzUrl).toContain('https://media.raize.fit/exercises/3d/barbell-bench-press-human-3d.usdz');
    expect(body.data.storageProvider).toBe('cloudflare_r2');
    expect(body.data.bucket).toBe('raize-media');
    expect(body.data.meshPolycount).toBe(42500);
    expect(body.data.rigBonesCount).toBe(68);
  });

  it('POST /api/v1/workouts/exercises/:slug/media/presigned-upload generates signed R2 upload parameter', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/workouts/exercises/barbell-bench-press/media/presigned-upload',
      payload: {
        filename: 'barbell-bench-press-human-3d.glb',
        contentType: 'model/gltf-binary',
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.uploadUrl).toContain('r2.cloudflarestorage.com');
    expect(body.data.publicUrl).toContain('media.raize.fit');
    expect(body.data.headers['Content-Type']).toBe('model/gltf-binary');
  });

  it('POST /api/v1/billing/subscription/cancel cancels user active subscription', async () => {
    // 1. Register a test user
    const uniqueEmail = `subscriber_${Date.now()}@example.com`;
    const regRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: uniqueEmail,
        password: 'SecurePassword2026!',
        firstName: 'Ngozi',
        lastName: 'Eze',
        dateOfBirth: '1995-04-12',
        consentTerms: true,
        consentHealthData: true,
      },
    });
    const token = regRes.json().data.token;

    // 2. Cancel subscription
    const cancelRes = await app.inject({
      method: 'POST',
      url: '/api/v1/billing/subscription/cancel',
      headers: {
        authorization: `Bearer ${token}`,
      },
    });

    expect(cancelRes.statusCode).toBe(200);
    const body = cancelRes.json();
    expect(body.success).toBe(true);
    expect(body.data.status).toBe('cancelled');
    expect(body.message).toContain('cancelled');
  });

  it('DELETE /api/v1/auth/account permanently deletes user account under NDPA Section 24', async () => {
    // 1. Register a user to delete
    const uniqueEmail = `to_delete_${Date.now()}@example.com`;
    const regRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: uniqueEmail,
        password: 'DeleteMePassword123!',
        firstName: 'Temporary',
        lastName: 'Athlete',
        dateOfBirth: '1992-01-01',
        consentTerms: true,
        consentHealthData: true,
      },
    });
    const token = regRes.json().data.token;

    // 2. Delete account
    const delRes = await app.inject({
      method: 'DELETE',
      url: '/api/v1/auth/account',
      headers: {
        authorization: `Bearer ${token}`,
      },
    });

    expect(delRes.statusCode).toBe(200);
    const body = delRes.json();
    expect(body.success).toBe(true);
    expect(body.message).toContain('permanently deleted');

    // 3. Attempting to login with deleted user credentials fails
    const loginRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: {
        email: uniqueEmail,
        password: 'DeleteMePassword123!',
      },
    });
    expect(loginRes.statusCode).toBe(401);
  });

  it('PATCH /api/v1/dashboard/step-target updates user custom daily step target', async () => {
    // 1. Register a user
    const email = `steps_user_${Date.now()}@example.com`;
    const regRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email,
        password: 'Password123!',
        firstName: 'Steps',
        lastName: 'Athlete',
        dateOfBirth: '1995-04-12',
        consentTerms: true,
        consentHealthData: true,
      },
    });
    const token = regRes.json().data.token;

    // 2. Initial dashboard summary defaults to 10,000 steps
    const initSummaryRes = await app.inject({
      method: 'GET',
      url: '/api/v1/dashboard/daily-summary',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(initSummaryRes.statusCode).toBe(200);
    expect(initSummaryRes.json().data.steps.targetCount).toBe(10000);

    // 3. Update step target to 12,500
    const updateRes = await app.inject({
      method: 'PATCH',
      url: '/api/v1/dashboard/step-target',
      headers: { authorization: `Bearer ${token}` },
      payload: { targetSteps: 12500 },
    });
    expect(updateRes.statusCode).toBe(200);
    const updateBody = updateRes.json();
    expect(updateBody.success).toBe(true);
    expect(updateBody.data.targetSteps).toBe(12500);

    // 4. Verify dashboard summary reflects updated target
    const updatedSummaryRes = await app.inject({
      method: 'GET',
      url: '/api/v1/dashboard/daily-summary',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(updatedSummaryRes.statusCode).toBe(200);
    expect(updatedSummaryRes.json().data.steps.targetCount).toBe(12500);

    // 5. Rejects out-of-range target (e.g. 500 steps)
    const invalidRes = await app.inject({
      method: 'PATCH',
      url: '/api/v1/dashboard/step-target',
      headers: { authorization: `Bearer ${token}` },
      payload: { targetSteps: 500 },
    });
    expect(invalidRes.statusCode).toBe(400);
    expect(['FST_ERR_VALIDATION', 'INVALID_STEP_TARGET']).toContain(invalidRes.json().error.code);
  });
});

