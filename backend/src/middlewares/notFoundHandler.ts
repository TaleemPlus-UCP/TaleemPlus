import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { sendError } from '../utils/apiResponse';

export function notFoundHandler(req: Request, res: Response): void {
  sendError(res, HttpStatus.NOT_FOUND, `Route ${req.method} ${req.originalUrl} does not exist.`);
}
