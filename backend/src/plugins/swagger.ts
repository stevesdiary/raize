import fp from 'fastify-plugin';
import fastifySwagger from '@fastify/swagger';
import fastifySwaggerUI from '@fastify/swagger-ui';
import { FastifyInstance } from 'fastify';

export const swaggerPlugin = fp(async (fastify: FastifyInstance) => {
  await fastify.register(fastifySwagger, {
    openapi: {
      info: {
        title: 'Raize Unified Fitness Platform API',
        description:
          'Commercial production API powering Raize: structured resistance training (LADDER), outdoor GPS telemetry (Strava), and localized Nigerian nutrition & food diary (MyFitnessPal). Compliant with NDPA 2023, CAMA 2020, and RFC 9106 Argon2id.',
        version: '1.0.0',
        contact: {
          name: 'Raize Engineering Team',
          email: 'support@raize.fit',
          url: 'https://raize.fit',
        },
      },
      servers: [
        { url: 'http://localhost:3000', description: 'Local Development Server' },
        { url: 'https://api.raize.fit', description: 'Production Gateway' },
      ],
      tags: [
        {
          name: 'Authentication',
          description: 'User onboarding, NDPA 2023 affirmative consent, Argon2id security, JWT sessions, and SendByte emails',
        },
        {
          name: 'Assessments & PAR-Q Safety',
          description: 'Comprehensive 6-stage assessment, PAR-Q cardiac safety gates (E05), and medical intercepts',
        },
        {
          name: 'Recommendations & Blueprint Engine',
          description: '7-factor activity suitability scoring, 6-D athletic classification, and 7-day training blueprint generation',
        },
        {
          name: 'Dashboard',
          description: 'Unified athlete daily summary, calorie equation balance, today workout status, and streak tracking',
        },
        {
          name: 'Workouts & Progressive Overload',
          description: 'Exercise library, live LADDER tracker, automatic PR detection (Brzycki 1RM), and total volume tonnage',
        },
        {
          name: 'Activities & GPS Telemetry',
          description: 'Live GPS run telemetry, 250m privacy zone masking, manual logging, and vector routes',
        },
        {
          name: 'Nutrition & Nigerian Food Diary',
          description: 'Verified Nigerian food catalog (pounded yam, egusi, suya), local portion units (wrap, derica), and macro budgets',
        },
        {
          name: 'Billing & Paystack',
          description: 'Paystack checkout initialization, webhook handling, and statutory CAMA 2020 6-year accounting retention',
        },
        {
          name: 'Offline Synchronization',
          description: 'Offline mutation outbox batch sync, two-phase idempotency locking, and poison-pill quarantine',
        },
        {
          name: 'Community & Social Feed',
          description: 'Activity social feed, kudos, comments, and challenges',
        },
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
            description: 'Enter your JWT token obtained from /api/v1/auth/login or /api/v1/auth/register',
          },
        },
      },
    },
  });

  await fastify.register(fastifySwaggerUI, {
    routePrefix: '/docs',
    uiConfig: {
      docExpansion: 'list',
      deepLinking: true,
      displayRequestDuration: true,
      filter: true,
      tryItOutEnabled: true,
      defaultModelsExpandDepth: 2,
      defaultModelExpandDepth: 2,
    },
  });
});

