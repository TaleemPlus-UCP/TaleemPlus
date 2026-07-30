import path from 'path';
import dotenv from 'dotenv';
import { z } from 'zod';

// Jest sets NODE_ENV=test automatically, so this picks .env.test in the test
// suite (a separate DB/secrets, never the developer's real .env) and .env
// everywhere else. `override: true` is required because @prisma/client's
// generated runtime auto-loads the plain `.env` file as an import side
// effect (regardless of NODE_ENV) the moment it's first required anywhere
// in the app — without this, that unrelated auto-load can win the race and
// silently pin DATABASE_URL/etc. to the dev file even under NODE_ENV=test.
dotenv.config({
  path: path.join(__dirname, '..', '..', process.env.NODE_ENV === 'test' ? '.env.test' : '.env'),
  override: true,
});

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  API_PREFIX: z.string().default('/api/v1'),
  CORS_ORIGINS: z.string().default(''),

  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET must be at least 32 characters'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_SECRET: z.string().min(32, 'JWT_REFRESH_SECRET must be at least 32 characters'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('30d'),

  PASSWORD_RESET_TOKEN_EXPIRES_MIN: z.coerce.number().int().positive().default(30),
  CLIENT_RESET_PASSWORD_URL: z.string().url().default('https://app.taleemplus.com/reset-password'),

  SMTP_HOST: z.string().optional().default(''),
  SMTP_PORT: z.coerce.number().int().positive().default(587),
  SMTP_SECURE: z.coerce.boolean().default(false),
  SMTP_USER: z.string().optional().default(''),
  SMTP_PASSWORD: z.string().optional().default(''),
  SMTP_FROM_NAME: z.string().default('TaleemPlus'),
  SMTP_FROM_EMAIL: z.string().default('no-reply@taleemplus.app'),

  CLOUDINARY_CLOUD_NAME: z.string().optional().default(''),
  CLOUDINARY_API_KEY: z.string().optional().default(''),
  CLOUDINARY_API_SECRET: z.string().optional().default(''),

  RATE_LIMIT_WINDOW_MIN: z.coerce.number().int().positive().default(15),
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(100),
  AUTH_RATE_LIMIT_WINDOW_MIN: z.coerce.number().int().positive().default(15),
  AUTH_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(10),

  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'http', 'debug']).default('info'),
}).superRefine((data, ctx) => {
  // Empty CORS_ORIGINS makes the cors() middleware reflect/allow any
  // origin (fine in dev, not fine in prod) — fail fast at boot instead of
  // silently shipping an open CORS policy.
  if (data.NODE_ENV === 'production' && data.CORS_ORIGINS.trim() === '') {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'CORS_ORIGINS must be set to a comma-separated allowlist in production.',
      path: ['CORS_ORIGINS'],
    });
  }
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  // eslint-disable-next-line no-console
  console.error('Invalid environment configuration:', parsed.error.flatten().fieldErrors);
  throw new Error('Invalid environment configuration. Check .env against .env.example.');
}

export const env = {
  ...parsed.data,
  isProduction: parsed.data.NODE_ENV === 'production',
  isDevelopment: parsed.data.NODE_ENV === 'development',
  isTest: parsed.data.NODE_ENV === 'test',
  corsOrigins: parsed.data.CORS_ORIGINS.split(',').map((o) => o.trim()).filter(Boolean),
  smtpConfigured: Boolean(parsed.data.SMTP_HOST),
  cloudinaryConfigured: Boolean(parsed.data.CLOUDINARY_CLOUD_NAME),
};
