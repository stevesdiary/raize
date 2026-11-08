import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../../db/index.js';
import { users, userProfiles, userConsents, notificationPreferences } from '../../db/schema/index.js';
import { eq, or, sql } from 'drizzle-orm';
import { hashPassword, verifyPassword, hashSha256 } from '../../utils/security.js';
import { calculateAge } from '../../utils/calculator.js';
import { sendWelcomeEmail, sendPasswordResetEmail } from '../../services/email.service.js';

export async function authRoutes(fastify: FastifyInstance) {
  // Register User (FR-001, NDPA Compliance)
  fastify.post('/register', {
    schema: {
      tags: ['Authentication'],
      summary: 'Register a new athlete account',
      description:
        'Registers a new user with strict 18+ age validation, NDPA 2023 affirmative consent, Argon2id password hashing, and dispatches a welcome email via SendByte.',
      body: {
        type: 'object',
        required: ['email', 'password', 'dateOfBirth', 'consentTerms'],
        properties: {
          email: { type: 'string', format: 'email', description: 'User email address', example: 'ada.okonkwo@raize.fit' },
          username: { type: 'string', pattern: '^[a-zA-Z0-9_.-]{3,30}$', description: 'Unique athlete username / handle for leaderboards and login', example: 'ada_runner' },
          password: { type: 'string', minLength: 8, description: 'Secure user password', example: 'Password123!Secure' },
          firstName: { type: 'string', description: 'First name', example: 'Ada' },
          lastName: { type: 'string', description: 'Last name', example: 'Okonkwo' },
          dateOfBirth: { type: 'string', format: 'date', description: 'Date of birth (strict 18+ verification: YYYY-MM-DD)', example: '1998-05-14' },
          biologicalSex: { type: 'string', enum: ['male', 'female', 'prefer_not_to_say'], description: 'Biological sex for BMR/TDEE calculation', example: 'female' },
          countryCode: { type: 'string', default: 'NG', description: 'ISO 3166-1 alpha-2 country code', example: 'NG' },
          unitSystem: { type: 'string', enum: ['metric', 'imperial'], default: 'metric', description: 'Measurement unit preference', example: 'metric' },
          consentHealthData: { type: 'boolean', default: true, description: 'NDPA 2023 consent to process health and biometric data', example: true },
          consentTerms: { type: 'boolean', description: 'Mandatory affirmative consent to terms of service', example: true },
        },
        examples: [
          {
            email: 'ada.okonkwo@raize.fit',
            password: 'Password123!Secure',
            firstName: 'Ada',
            lastName: 'Okonkwo',
            dateOfBirth: '1998-05-14',
            biologicalSex: 'female',
            countryCode: 'NG',
            unitSystem: 'metric',
            consentHealthData: true,
            consentTerms: true,
          },
        ],
      },
      response: {
        201: {
          type: 'object',
          description: 'Registration successful — returns user profile and JWT session token',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                user: {
                  type: 'object',
                  properties: {
                    id: { type: 'string', format: 'uuid', example: 'd91a6b78-b631-4248-8d20-c57adfef03bb' },
                    email: { type: 'string', example: 'ada.okonkwo@raize.fit' },
                    username: { type: 'string', example: 'ada_runner' },
                    role: { type: 'string', example: 'user' },
                    age: { type: 'integer', example: 28 },
                  },
                },
                token: { type: 'string', example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImQ5MWE2Yjc4LWI2MzEtNDI0OC04ZDIwLWM1N2FkZmVmMDNiYiJ9...' },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                user: {
                  id: 'd91a6b78-b631-4248-8d20-c57adfef03bb',
                  email: 'ada.okonkwo@raize.fit',
                  username: 'ada_runner',
                  role: 'user',
                  age: 28,
                },
                token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImQ5MWE2Yjc4LWI2MzEtNDI0OC04ZDIwLWM1N2FkZmVmMDNiYiJ9...',
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const body = request.body as {
      email: string;
      username?: string;
      password: string;
      firstName?: string;
      lastName?: string;
      dateOfBirth: string; // YYYY-MM-DD
      biologicalSex?: 'male' | 'female' | 'prefer_not_to_say';
      countryCode?: string;
      unitSystem?: 'metric' | 'imperial';
      consentHealthData: boolean;
      consentTerms: boolean;
    };

    if (!body.email || !body.password || !body.dateOfBirth) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'Email, password, and date of birth are required' },
      });
    }

    // Age validation: Strict 18+ requirement for initial launch
    const age = calculateAge(body.dateOfBirth);
    if (age < 18) {
      return reply.status(400).send({
        success: false,
        error: {
          code: 'UNDERAGE_NOT_PERMITTED',
          message: 'Users must be at least 18 years of age to register during initial release',
        },
      });
    }

    if (!body.consentTerms) {
      return reply.status(400).send({
        success: false,
        error: { code: 'CONSENT_REQUIRED', message: 'Terms of service consent is mandatory' },
      });
    }

    // Check duplicate email
    const [existing] = await db.select().from(users).where(eq(users.email, body.email.toLowerCase().trim()));
    if (existing) {
      return reply.status(409).send({
        success: false,
        error: { code: 'EMAIL_ALREADY_EXISTS', message: 'An account with this email already exists' },
      });
    }

    // Username validation and uniqueness (for leaderboards and handle login)
    let finalUsername = body.username ? body.username.trim().replace(/^@/, '') : '';
    if (finalUsername) {
      if (!/^[a-zA-Z0-9_.-]{3,30}$/.test(finalUsername)) {
        return reply.status(400).send({
          success: false,
          error: {
            code: 'INVALID_USERNAME',
            message: 'Username must be 3-30 characters with letters, numbers, underscores, or periods only',
          },
        });
      }

      const [existingUsername] = await db
        .select()
        .from(users)
        .where(eq(sql`lower(${users.username})`, finalUsername.toLowerCase()));

      if (existingUsername) {
        return reply.status(409).send({
          success: false,
          error: {
            code: 'USERNAME_ALREADY_EXISTS',
            message: 'This username is already taken. Please choose another username.',
          },
        });
      }
    } else {
      // Auto-generate unique athletic handle if not provided
      const baseHandle = (body.firstName ? body.firstName : body.email.split('@')[0])
        .toLowerCase()
        .replace(/[^a-z0-9]/g, '');
      finalUsername = `${baseHandle || 'athlete'}_${Math.random().toString(36).substring(2, 6)}`;
    }

    const passwordHash = await hashPassword(body.password);
    const clientIp = request.ip || '127.0.0.1';
    const ipHash = hashSha256(clientIp);

    // Create user and profile
    const [newUser] = await db
      .insert(users)
      .values({
        email: body.email.toLowerCase().trim(),
        username: finalUsername,
        passwordHash,
        role: 'user',
        status: 'active',
      })
      .returning();

    await db.insert(userProfiles).values({
      userId: newUser.id,
      firstName: body.firstName || null,
      lastName: body.lastName || null,
      dateOfBirth: body.dateOfBirth,
      biologicalSex: body.biologicalSex || 'prefer_not_to_say',
      countryCode: body.countryCode || 'NG',
      unitSystem: body.unitSystem || 'metric',
      timezone: 'Africa/Lagos',
    });

    // Record NDPA 2023 affirmative consents
    await db.insert(userConsents).values([
      {
        userId: newUser.id,
        consentType: 'terms_of_service',
        granted: true,
        ipAddressHash: ipHash,
        policyVersion: '2026.1',
      },
      {
        userId: newUser.id,
        consentType: 'health_data_processing',
        granted: body.consentHealthData ?? true,
        ipAddressHash: ipHash,
        policyVersion: '2026.1',
      },
    ]);

    await db.insert(notificationPreferences).values({
      userId: newUser.id,
    });

    const token = fastify.jwt.sign({
      id: newUser.id,
      email: newUser.email,
      role: newUser.role,
    });

    // Send Welcome Email via SendByte (sendbyte.africa)
    sendWelcomeEmail(newUser.email, body.firstName || '').catch((err) => {
      request.log.error(err, 'Failed to dispatch SendByte welcome email');
    });

    return reply.status(201).send({
      success: true,
      data: {
        user: {
          id: newUser.id,
          email: newUser.email,
          username: newUser.username,
          role: newUser.role,
          age,
        },
        token,
      },
    });
  });

  // Login (FR-001)
  fastify.post('/login', {
    schema: {
      tags: ['Authentication'],
      summary: 'Authenticate with email/username & password',
      description: 'Verifies credentials via Argon2id RFC 9106 and issues a JWT bearer token.',
      body: {
        type: 'object',
        required: ['password'],
        properties: {
          email: { type: 'string', description: 'Registered email address', example: 'ada.okonkwo@raize.fit' },
          username: { type: 'string', description: 'Registered athlete username', example: 'ada_runner' },
          identifier: { type: 'string', description: 'Email address or username (with or without @)', example: 'ada_runner' },
          password: { type: 'string', description: 'Account password', example: 'Password123!Secure' },
        },
        examples: [
          {
            identifier: 'ada_runner',
            password: 'Password123!Secure',
          },
          {
            email: 'ada.okonkwo@raize.fit',
            password: 'Password123!Secure',
          },
        ],
      },
      response: {
        200: {
          type: 'object',
          description: 'Login successful — returns user profile and JWT bearer token',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                user: {
                  type: 'object',
                  properties: {
                    id: { type: 'string', format: 'uuid', example: 'd91a6b78-b631-4248-8d20-c57adfef03bb' },
                    email: { type: 'string', example: 'ada.okonkwo@raize.fit' },
                    username: { type: 'string', example: 'ada_runner' },
                    role: { type: 'string', example: 'user' },
                    status: { type: 'string', example: 'active' },
                    profile: {
                      type: 'object',
                      properties: {
                        userId: { type: 'string', format: 'uuid', example: 'd91a6b78-b631-4248-8d20-c57adfef03bb' },
                        firstName: { type: 'string', example: 'Ada' },
                        lastName: { type: 'string', example: 'Okonkwo' },
                        dateOfBirth: { type: 'string', example: '1998-05-14' },
                        biologicalSex: { type: 'string', example: 'female' },
                        unitSystem: { type: 'string', example: 'metric' },
                        countryCode: { type: 'string', example: 'NG' },
                        timezone: { type: 'string', example: 'Africa/Lagos' },
                      },
                    },
                  },
                },
                token: { type: 'string', example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImQ5MWE2Yjc4LWI2MzEtNDI0OC04ZDIwLWM1N2FkZmVmMDNiYiJ9...' },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                user: {
                  id: 'd91a6b78-b631-4248-8d20-c57adfef03bb',
                  email: 'ada.okonkwo@raize.fit',
                  username: 'ada_runner',
                  role: 'user',
                  status: 'active',
                  profile: {
                    userId: 'd91a6b78-b631-4248-8d20-c57adfef03bb',
                    firstName: 'Ada',
                    lastName: 'Okonkwo',
                    dateOfBirth: '1998-05-14',
                    biologicalSex: 'female',
                    unitSystem: 'metric',
                    countryCode: 'NG',
                    timezone: 'Africa/Lagos',
                  },
                },
                token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImQ5MWE2Yjc4LWI2MzEtNDI0OC04ZDIwLWM1N2FkZmVmMDNiYiJ9...',
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { email, username, identifier, password } = request.body as {
      email?: string;
      username?: string;
      identifier?: string;
      password?: string;
    };

    const loginId = (identifier || email || username || '').trim();

    if (!loginId || !password) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'Email/username and password are required' },
      });
    }

    const cleanId = loginId.toLowerCase();
    const cleanUsername = cleanId.startsWith('@') ? cleanId.substring(1) : cleanId;

    const [user] = await db
      .select()
      .from(users)
      .where(
        or(
          eq(sql`lower(${users.email})`, cleanId),
          eq(sql`lower(${users.username})`, cleanUsername)
        )
      );

    if (!user || !user.passwordHash) {
      return reply.status(401).send({
        success: false,
        error: { code: 'AUTH_INVALID_CREDENTIALS', message: 'Invalid email/username or password' },
      });
    }

    const isMatch = await verifyPassword(user.passwordHash, password);
    if (!isMatch) {
      return reply.status(401).send({
        success: false,
        error: { code: 'AUTH_INVALID_CREDENTIALS', message: 'Invalid email/username or password' },
      });
    }

    const [profile] = await db.select().from(userProfiles).where(eq(userProfiles.userId, user.id));

    const token = fastify.jwt.sign({
      id: user.id,
      email: user.email,
      username: user.username,
      role: user.role,
    });

    return reply.send({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          role: user.role,
          status: user.status,
          profile,
        },
        token,
      },
    });
  });

  // Authenticated Current User
  fastify.get('/me', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Authentication'],
      summary: 'Get currently authenticated user & profile',
      description: 'Returns profile details, measurement unit preferences, and status for the active JWT session.',
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          description: 'Current user profile data',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: 'd91a6b78-b631-4248-8d20-c57adfef03bb' },
                email: { type: 'string', example: 'ada.okonkwo@raize.fit' },
                username: { type: 'string', example: 'ada_runner' },
                role: { type: 'string', example: 'user' },
                status: { type: 'string', example: 'active' },
                profile: {
                  type: 'object',
                  properties: {
                    userId: { type: 'string', format: 'uuid', example: 'd91a6b78-b631-4248-8d20-c57adfef03bb' },
                    firstName: { type: 'string', example: 'Ada' },
                    lastName: { type: 'string', example: 'Okonkwo' },
                    dateOfBirth: { type: 'string', example: '1998-05-14' },
                    biologicalSex: { type: 'string', example: 'female' },
                    unitSystem: { type: 'string', example: 'metric' },
                    countryCode: { type: 'string', example: 'NG' },
                  },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: 'd91a6b78-b631-4248-8d20-c57adfef03bb',
                email: 'ada.okonkwo@raize.fit',
                username: 'ada_runner',
                role: 'user',
                status: 'active',
                profile: {
                  userId: 'd91a6b78-b631-4248-8d20-c57adfef03bb',
                  firstName: 'Ada',
                  lastName: 'Okonkwo',
                  dateOfBirth: '1998-05-14',
                  biologicalSex: 'female',
                  unitSystem: 'metric',
                  countryCode: 'NG',
                },
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const [user] = await db.select().from(users).where(eq(users.id, userPayload.id));
    if (!user) {
      return reply.status(404).send({
        success: false,
        error: { code: 'RESOURCE_NOT_FOUND', message: 'User not found' },
      });
    }

    const [profile] = await db.select().from(userProfiles).where(eq(userProfiles.userId, user.id));

    return reply.send({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
        status: user.status,
        profile,
      },
    });
  });

  // Forgot Password (FR-001 via SendByte)
  fastify.post('/forgot-password', {
    schema: {
      tags: ['Authentication'],
      summary: 'Request password reset email',
      description: 'Generates a signed 1-hour password reset token and dispatches an email via SendByte Africa.',
      body: {
        type: 'object',
        required: ['email'],
        properties: {
          email: { type: 'string', format: 'email', description: 'Registered user email', example: 'ada.okonkwo@raize.fit' },
        },
        examples: [
          {
            email: 'ada.okonkwo@raize.fit',
          },
        ],
      },
      response: {
        200: {
          type: 'object',
          description: 'Password reset dispatch acknowledgment',
          properties: {
            success: { type: 'boolean', example: true },
            message: { type: 'string', example: 'If an account exists with this email, a password reset link has been dispatched via SendByte.' },
          },
          examples: [
            {
              success: true,
              message: 'If an account exists with this email, a password reset link has been dispatched via SendByte.',
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { email } = request.body as { email?: string };
    if (!email) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'Email is required' },
      });
    }

    const [user] = await db.select().from(users).where(eq(users.email, email.toLowerCase().trim()));
    if (user) {
      const resetToken = fastify.jwt.sign({ id: user.id, purpose: 'password_reset' }, { expiresIn: '1h' });
      sendPasswordResetEmail(user.email, resetToken).catch((err) => {
        request.log.error(err, 'Failed to dispatch SendByte password reset email');
      });
    }

    // Always return success to prevent email enumeration
    return reply.send({
      success: true,
      message: 'If an account exists with this email, a password reset link has been dispatched via SendByte.',
    });
  });

  // Delete Account (NDPA Section 24 Right to Erasure / GDPR Article 17)
  fastify.delete('/account', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Authentication'],
      summary: 'Permanently delete athlete account & personal data',
      description: 'Executes NDPA Section 24 Right to Erasure, cascading deletion of biometrics, profile, and workout logs, with anonymized financial records for CAMA 2020 compliance.',
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            message: { type: 'string', example: 'Account and associated personal records permanently deleted in compliance with NDPA Section 24.' },
          },
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };

    await db.delete(users).where(eq(users.id, userPayload.id));

    return reply.send({
      success: true,
      message: 'Account and associated personal records permanently deleted in compliance with NDPA Section 24.',
    });
  });
}

