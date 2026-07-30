import { NextFunction, Request, Response } from 'express';
import { Prisma } from '@prisma/client';
import { ZodError } from 'zod';
import { env } from '../config/env';
import { logger } from '../config/logger';
import { AppError } from '../exceptions/AppError';
import { HttpStatus } from '../constants/httpStatus';
import { sendError } from '../utils/apiResponse';

/** Must be registered after all routes. Every error in the app funnels through here. */
export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction): void {
  if (err instanceof ZodError) {
    logger.warn(`Validation error on ${req.method} ${req.originalUrl}: ${err.message}`);
    sendError(res, HttpStatus.UNPROCESSABLE_ENTITY, 'Validation failed', err.flatten());
    return;
  }

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') {
      sendError(res, HttpStatus.CONFLICT, `A record with this ${(err.meta?.target as string[])?.join(', ') ?? 'value'} already exists.`);
      return;
    }
    if (err.code === 'P2025') {
      sendError(res, HttpStatus.NOT_FOUND, 'Requested resource was not found.');
      return;
    }
    logger.error(`Prisma error ${err.code}: ${err.message}`);
    sendError(res, HttpStatus.INTERNAL_SERVER_ERROR, 'A database error occurred.');
    return;
  }

  if (err instanceof AppError) {
    if (err.statusCode >= HttpStatus.INTERNAL_SERVER_ERROR) {
      logger.error(`${err.name}: ${err.message}`, { stack: err.stack });
    } else {
      logger.warn(`${err.name}: ${err.message} [${req.method} ${req.originalUrl}]`);
    }
    sendError(res, err.statusCode, err.message, err.details);
    return;
  }

  const error = err as Error;
  logger.error(`Unhandled error on ${req.method} ${req.originalUrl}: ${error.message}`, { stack: error.stack });
  sendError(
    res,
    HttpStatus.INTERNAL_SERVER_ERROR,
    env.isProduction ? 'Something went wrong. Please try again later.' : error.message,
  );
}
