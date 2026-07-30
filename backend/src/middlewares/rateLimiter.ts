import rateLimit from 'express-rate-limit';
import { env } from '../config/env';
import { HttpStatus } from '../constants/httpStatus';
import { sendError } from '../utils/apiResponse';

/** General API-wide limiter. */
export const globalRateLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MIN * 60 * 1000,
  max: env.RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req, res) => {
    sendError(res, HttpStatus.TOO_MANY_REQUESTS, 'Too many requests. Please try again later.');
  },
});

/**
 * Stricter limiter for auth endpoints (login/register/forgot-password/
 * security-question) — these are the classic brute-force/enumeration
 * targets, so they get a tighter budget than the rest of the API.
 */
export const authRateLimiter = rateLimit({
  windowMs: env.AUTH_RATE_LIMIT_WINDOW_MIN * 60 * 1000,
  max: env.AUTH_RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false,
  handler: (_req, res) => {
    sendError(res, HttpStatus.TOO_MANY_REQUESTS, 'Too many attempts. Please wait before trying again.');
  },
});
