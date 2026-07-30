import { createApp } from './app';
import { connectDatabase, disconnectDatabase } from './config/database';
import { env } from './config/env';
import { logger } from './config/logger';

async function bootstrap(): Promise<void> {
  await connectDatabase();

  const app = createApp();
  const server = app.listen(env.PORT, () => {
    logger.info(`TaleemPlus API listening on port ${env.PORT} [${env.NODE_ENV}]`);
    logger.info(`Swagger docs available at http://localhost:${env.PORT}/docs`);
  });

  const shutdown = async (signal: string): Promise<void> => {
    logger.info(`${signal} received. Shutting down gracefully...`);
    server.close(async () => {
      await disconnectDatabase();
      process.exit(0);
    });
    // Force-exit if graceful shutdown hangs.
    setTimeout(() => process.exit(1), 10_000).unref();
  };

  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));

  process.on('unhandledRejection', (reason) => {
    logger.error(`Unhandled promise rejection: ${String(reason)}`);
  });

  process.on('uncaughtException', (error) => {
    logger.error(`Uncaught exception: ${error.message}`, { stack: error.stack });
    process.exit(1);
  });
}

bootstrap().catch((error) => {
  logger.error(`Fatal error during bootstrap: ${(error as Error).message}`, { stack: (error as Error).stack });
  process.exit(1);
});
