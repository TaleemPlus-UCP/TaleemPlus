import { Response } from 'express';

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

interface SuccessBody<T> {
  success: true;
  message: string;
  data: T;
  meta?: PaginationMeta;
}

interface ErrorBody {
  success: false;
  message: string;
  errors?: unknown;
}

/** Standard success envelope used by every endpoint in the API. */
export function sendSuccess<T>(
  res: Response,
  statusCode: number,
  message: string,
  data: T,
  meta?: PaginationMeta,
): Response<SuccessBody<T>> {
  const body: SuccessBody<T> = { success: true, message, data };
  if (meta) body.meta = meta;
  return res.status(statusCode).json(body);
}

/** Standard error envelope used by the centralized error handler. */
export function sendError(res: Response, statusCode: number, message: string, errors?: unknown): Response<ErrorBody> {
  const body: ErrorBody = { success: false, message };
  if (errors !== undefined) body.errors = errors;
  return res.status(statusCode).json(body);
}

export function buildPaginationMeta(page: number, limit: number, total: number): PaginationMeta {
  return { page, limit, total, totalPages: Math.max(1, Math.ceil(total / limit)) };
}
