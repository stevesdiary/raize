import { buildApp } from './app.js';
import { env } from './config/env.js';
import { client } from './db/index.js';

const server = buildApp();

const start = async () => {
  try {
    await server.listen({ port: env.PORT, host: env.HOST });
    console.log(`🚀 Raize Fitness Backend API running at http://${env.HOST}:${env.PORT}`);
    console.log(`📖 Swagger API Documentation available at http://${env.HOST}:${env.PORT}/docs`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

// Graceful Shutdown
let isShuttingDown = false;
const shutdown = async (signal: string) => {
  if (isShuttingDown) return;
  isShuttingDown = true;
  console.log(`Received ${signal}. Gracefully shutting down...`);

  // Hard safety timeout: if graceful shutdown exceeds 1.5s, exit immediately
  const forceTimer = setTimeout(() => {
    console.warn('Graceful shutdown timeout exceeded (1.5s). Forcing process exit...');
    process.exit(0);
  }, 1500);
  forceTimer.unref();

  try {
    await server.close();
    await client.end({ timeout: 1 }).catch(() => {});
    clearTimeout(forceTimer);
    console.log('Server closed successfully.');
    process.exit(0);
  } catch (err) {
    console.error('Error during shutdown:', err);
    process.exit(1);
  }
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

start();

