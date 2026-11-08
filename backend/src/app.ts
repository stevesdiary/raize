import fastify, { FastifyInstance } from 'fastify';
import fastifyCors from '@fastify/cors';
import fastifySensible from '@fastify/sensible';
import fastifyRateLimit from '@fastify/rate-limit';
import { env } from './config/env.js';
import { authPlugin } from './plugins/auth.js';
import { swaggerPlugin } from './plugins/swagger.js';
import { errorHandler } from './plugins/errorHandler.js';

// Route Modules
import { authRoutes } from './modules/auth/auth.routes.js';
import { assessmentRoutes } from './modules/assessment/assessment.routes.js';
import { recommendationRoutes } from './modules/recommendations/recommendations.routes.js';
import { workoutRoutes } from './modules/workouts/workouts.routes.js';
import { activityRoutes } from './modules/activities/activities.routes.js';
import { nutritionRoutes } from './modules/nutrition/nutrition.routes.js';
import { communityRoutes } from './modules/community/community.routes.js';
import { billingRoutes } from './modules/billing/billing.routes.js';
import { syncRoutes } from './modules/sync/sync.routes.js';
import { dashboardRoutes } from './modules/dashboard/dashboard.routes.js';

export function buildApp(): FastifyInstance {
  const app = fastify({
    logger: env.NODE_ENV !== 'test',
    forceCloseConnections: true,
    ajv: {
      customOptions: {
        strict: false,
      },
    },
  });

  // Global Error Handler
  app.setErrorHandler(errorHandler);

  // Content Type Parser to handle empty JSON bodies gracefully
  app.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body, defaultDone) => {
    const strBody = typeof body === 'string' ? body : body?.toString() || '';
    if (!strBody.trim()) {
      defaultDone(null, {});
      return;
    }
    try {
      defaultDone(null, JSON.parse(strBody));
    } catch (err: any) {
      defaultDone(err, undefined);
    }
  });

  // Core Plugins
  app.register(fastifyCors, {
    origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN,
    credentials: true,
  });

  app.register(fastifySensible);

  app.register(fastifyRateLimit, {
    max: 1000,
    timeWindow: '1 minute',
  });

  app.register(authPlugin);
  app.register(swaggerPlugin);

  // Health Check
  app.get('/health', async () => {
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'raize-fitness-backend',
      version: '1.0.0',
    };
  });

  // API Version 1 Routes
  app.register(async (v1) => {
    v1.register(authRoutes, { prefix: '/auth' });
    v1.register(assessmentRoutes, { prefix: '/assessments' });
    v1.register(assessmentRoutes, { prefix: '/assessment' });
    v1.register(recommendationRoutes, { prefix: '/recommendations' });
    v1.register(workoutRoutes, { prefix: '/workouts' });
    v1.register(activityRoutes, { prefix: '/activities' });
    v1.register(nutritionRoutes, { prefix: '/nutrition' });
    v1.register(communityRoutes, { prefix: '/community' });
    v1.register(billingRoutes, { prefix: '/billing' });
    v1.register(syncRoutes, { prefix: '/sync' });
    v1.register(dashboardRoutes, { prefix: '/dashboard' });
  }, { prefix: '/api/v1' });

  return app;
}

