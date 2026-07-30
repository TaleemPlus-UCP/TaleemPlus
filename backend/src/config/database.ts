// `./env` must be imported before `@prisma/client` — Prisma's generated
// runtime auto-loads the plain `.env` file as an import side effect, and
// since dotenv never overrides an already-set var, importing it first here
// would silently defeat our own NODE_ENV-aware env.ts loading .env.test.
import { env } from './env';
import { PrismaClient } from '@prisma/client';
import { logger } from './logger';

declare global {
  // eslint-disable-next-line no-var
  var __prisma: PrismaClient | undefined;
}

/**
 * A single PrismaClient instance is reused across the process (and across
 * tsx watch reloads in dev via the global cache) so we never exhaust the
 * Postgres connection pool with duplicate clients.
 */
export const prisma =
  global.__prisma ??
  new PrismaClient({
    log: env.isDevelopment
      ? [
          { emit: 'event', level: 'query' },
          { emit: 'event', level: 'error' },
          { emit: 'event', level: 'warn' },
        ]
      : [{ emit: 'event', level: 'error' }],
  });

if (env.isDevelopment) {
  global.__prisma = prisma;
  // @ts-expect-error - prisma event typings don't cover 'query' cleanly with this log config
  prisma.$on('query', (e: { query: string; params: string; duration: number }) => {
    logger.debug(`prisma:query ${e.query} ${e.params} +${e.duration}ms`);
  });
}

// @ts-expect-error - see above
prisma.$on('error', (e: { message: string }) => logger.error(`prisma:error ${e.message}`));
// @ts-expect-error - see above
prisma.$on('warn', (e: { message: string }) => logger.warn(`prisma:warn ${e.message}`));

export async function connectDatabase(): Promise<void> {
  await prisma.$connect();
  logger.info('Database connected');
}

export async function disconnectDatabase(): Promise<void> {
  await prisma.$disconnect();
  logger.info('Database disconnected');
}
