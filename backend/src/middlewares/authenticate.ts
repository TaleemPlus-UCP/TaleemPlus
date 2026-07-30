import { NextFunction, Request, Response } from 'express';
import { UnauthorizedError } from '../exceptions/AppError';
import { verifyAccessToken } from '../utils/jwt';

/** Verifies the `Authorization: Bearer <token>` header and attaches `req.user`. */
export function authenticate(req: Request, _res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw new UnauthorizedError('Missing or malformed Authorization header.');
  }

  const token = header.slice('Bearer '.length).trim();
  const payload = verifyAccessToken(token);

  req.user = {
    id: payload.sub,
    role: payload.role,
    academyId: payload.academyId,
    accountStatus: payload.accountStatus,
  };

  next();
}
