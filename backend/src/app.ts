import compression from 'compression';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import express, { Express } from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env';
import { httpLogStream } from './config/logger';
import { swaggerSpec } from './config/swagger';
import { errorHandler } from './middlewares/errorHandler';
import { notFoundHandler } from './middlewares/notFoundHandler';
import { globalRateLimiter } from './middlewares/rateLimiter';
import { apiRouter } from './routes';
import { sendSuccess } from './utils/apiResponse';
import { HttpStatus } from './constants/httpStatus';

export function createApp(): Express {
  const app = express();

  // Behind a reverse proxy (Nginx/Railway/Render) in production, so req.ip
  // reflects the real client IP for rate limiting and audit logs.
  app.set('trust proxy', 1);

  app.use(helmet());
  app.use(
    cors({
      origin: env.corsOrigins.length > 0 ? env.corsOrigins : true,
      credentials: true,
    }),
  );
  app.use(compression());
  app.use(cookieParser());
  app.use(express.json({ limit: '2mb' }));
  app.use(express.urlencoded({ extended: true, limit: '2mb' }));
  app.use(morgan(env.isDevelopment ? 'dev' : 'combined', { stream: httpLogStream }));
  app.use(globalRateLimiter);

  app.get('/health', (_req, res) => {
    sendSuccess(res, HttpStatus.OK, 'OK', { uptime: process.uptime(), timestamp: new Date().toISOString() });
  });

  app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
  app.use(env.API_PREFIX, apiRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
