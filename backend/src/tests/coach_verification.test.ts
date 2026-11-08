import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { buildApp } from '../app.js';
import { FastifyInstance } from 'fastify';
import { client, db, users, coachProfiles } from '../db/index.js';
import { eq } from 'drizzle-orm';

describe('Coach Onboarding & 4-Pillar Verification Portal Endpoints', () => {
  let app: FastifyInstance;
  let coachToken: string;
  let coachUserId: string;
  let adminToken: string;
  let adminUserId: string;
  let createdCoachId: string;

  beforeAll(async () => {
    app = buildApp();
    await app.ready();

    // Register a coach applicant user
    const coachRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: `coach_${Date.now()}@example.com`,
        username: `coach_${Date.now()}`,
        password: 'Password123!',
        dateOfBirth: '1992-06-15',
        consentTerms: true,
        consentHealthData: true,
        consentLocation: true,
      },
    });
    const coachBody = coachRes.json();
    coachUserId = coachBody.data.user.id;
    coachToken = coachBody.data.token;

    // Register an admin user
    const adminRes = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        email: `admin_${Date.now()}@example.com`,
        username: `admin_${Date.now()}`,
        password: 'Password123!',
        dateOfBirth: '1985-01-20',
        consentTerms: true,
        consentHealthData: true,
        consentLocation: true,
      },
    });
    const adminBody = adminRes.json();
    adminUserId = adminBody.data.user.id;
    adminToken = adminBody.data.token;

    // Promote admin in db
    await db.update(users).set({ role: 'admin' }).where(eq(users.id, adminUserId));
  });

  afterAll(async () => {
    await app.close();
    await client.end();
  });

  it('GET /api/v1/coaches/banks returns supported Nigerian commercial & fintech banks', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/coaches/banks',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBeGreaterThanOrEqual(8);

    const gtbank = body.data.find((b: any) => b.code === '058');
    expect(gtbank).toBeDefined();
    expect(gtbank.name).toContain('Guaranty Trust Bank');
  });

  it('POST /api/v1/coaches/apply rejects if NDPA 2023 DPA is not accepted', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/coaches/apply',
      headers: {
        Authorization: `Bearer ${coachToken}`,
      },
      payload: {
        fullName: 'Coach Babatunde Adeleke',
        bio: 'Elite strength & conditioning coach specializing in progressive overload and Olympic weightlifting.',
        specialties: ['strength', 'hypertrophy', 'olympic_lifting'],
        experienceYears: 6,
        accreditationBody: 'NSCA',
        licenseNumber: 'NSCA-CSCS-89021',
        idType: 'NIN',
        idNumber: '19283746501',
        bankCode: '058',
        accountNumber: '0123456789',
        accountName: 'Babatunde Adeleke',
        ndpaDpaAccepted: false, // Intentionally false
      },
    });

    expect(res.statusCode).toBe(400);
    const body = res.json();
    expect(body.success).toBe(false);
    expect(body.error.code).toBe('NDPA_DPA_REQUIRED');
  });

  it('POST /api/v1/coaches/apply successfully submits application with accreditation & NUBAN bank details', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/coaches/apply',
      headers: {
        Authorization: `Bearer ${coachToken}`,
      },
      payload: {
        fullName: 'Coach Babatunde Adeleke',
        bio: 'Elite strength & conditioning coach specializing in progressive overload and Olympic weightlifting.',
        specialties: ['strength', 'hypertrophy', 'olympic_lifting'],
        experienceYears: 6,
        accreditationBody: 'NSCA',
        licenseNumber: 'NSCA-CSCS-89021',
        idType: 'NIN',
        idNumber: '19283746501',
        bankCode: '058',
        accountNumber: '0123456789',
        accountName: 'Babatunde Adeleke',
        ndpaDpaAccepted: true,
      },
    });

    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.fullName).toBe('Coach Babatunde Adeleke');
    expect(body.data.verificationStatus).toBe('pending');
    expect(body.data.accreditationBody).toBe('NSCA');
    expect(body.data.paystackRecipientCode).toBe('RCP_058_0123456789');

    createdCoachId = body.data.id;
  });

  it('GET /api/v1/coaches/me returns 4-pillar verification milestone breakdown', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/coaches/me',
      headers: {
        Authorization: `Bearer ${coachToken}`,
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.verificationStatus).toBe('pending');
    expect(body.data.isActive).toBe(false);

    // Verify 4-Pillar verification schema
    const audit = body.data.fourPillarAudit;
    expect(audit).toBeDefined();
    expect(audit.pillar1_identityKyc.provider).toContain('Smile ID');
    expect(audit.pillar2_accreditation.body).toBe('NSCA');
    expect(audit.pillar3_ndpaDpa.status).toBe('consented');
    expect(audit.pillar4_paystackPayout.status).toBe('active');
    expect(audit.pillar4_paystackPayout.recipientCode).toBe('RCP_058_0123456789');
  });

  it('GET /api/v1/coaches public directory does not display pending unverified coaches', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/coaches',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    const found = body.data.find((c: any) => c.id === createdCoachId);
    expect(found).toBeUndefined();
  });

  it('POST /api/v1/coaches/:id/review verifies coach accreditation, promotes user role, and sets active', async () => {
    const res = await app.inject({
      method: 'POST',
      url: `/api/v1/coaches/${createdCoachId}/review`,
      headers: {
        Authorization: `Bearer ${adminToken}`,
      },
      payload: {
        status: 'verified',
      },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.verificationStatus).toBe('verified');
    expect(body.data.isActive).toBe(true);

    // Verify user role was promoted in database
    const userInDb = await db.select().from(users).where(eq(users.id, coachUserId)).limit(1);
    expect(userInDb[0].role).toBe('coach');
  });

  it('GET /api/v1/coaches public directory now lists verified coach for athlete booking', async () => {
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/coaches',
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    const found = body.data.find((c: any) => c.id === createdCoachId);
    expect(found).toBeDefined();
    expect(found.fullName).toBe('Coach Babatunde Adeleke');
    expect(found.accreditationBody).toBe('NSCA');
    expect(found.monthlyRetainerNgn).toBe(25000);
  });

  it('GET /api/v1/coaches/:id returns detailed public coach profile', async () => {
    const res = await app.inject({
      method: 'GET',
      url: `/api/v1/coaches/${createdCoachId}`,
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.id).toBe(createdCoachId);
    expect(body.data.specialties).toContain('olympic_lifting');
  });
});

