import { NextFunction, Request, Response } from 'express';
import { UserRole } from '@prisma/client';
import { ForbiddenError, UnauthorizedError } from '../exceptions/AppError';

/** Restricts a route to one or more roles. Must run after `authenticate`. */
export function requireRoles(...roles: UserRole[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) throw new UnauthorizedError('Authentication required.');
    if (!roles.includes(req.user.role)) {
      throw new ForbiddenError(`This action requires one of the following roles: ${roles.join(', ')}.`);
    }
    next();
  };
}

/** Blocks pending/rejected accounts from every gated route. Must run after `authenticate`. */
export function requireActiveAccount(req: Request, _res: Response, next: NextFunction): void {
  if (!req.user) throw new UnauthorizedError('Authentication required.');
  if (req.user.accountStatus !== 'ACTIVE') {
    throw new ForbiddenError('Your account is not active. Contact your academy admin.');
  }
  next();
}
