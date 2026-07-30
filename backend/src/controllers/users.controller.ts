import { Request, Response } from 'express';
import { UserRole } from '@prisma/client';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { usersService } from '../services/users.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { toUserResponse } from '../utils/serializers';

/** Every route here is admin-only and req.user.academyId is set at registration for every ADMIN — this guard is defense-in-depth, not an expected path. */
function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { adminId: req.user.id, academyId: req.user.academyId };
}

export const listPending = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { role, page, limit } = req.query as unknown as { role?: UserRole; page: number; limit: number };
  const { items, meta } = await usersService.listPending(ctx, role, { page, limit });
  sendSuccess(res, HttpStatus.OK, 'Pending users.', items.map(toUserResponse), meta);
});

export const approve = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const user = await usersService.approve(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'User approved.', toUserResponse(user));
});

export const reject = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const user = await usersService.reject(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'User rejected.', toUserResponse(user));
});

export const listByRole = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { role, search, page, limit } = req.query as unknown as {
    role: UserRole;
    search?: string;
    page: number;
    limit: number;
  };
  const { items, meta } = await usersService.listByRole(ctx, role, search, { page, limit });
  sendSuccess(res, HttpStatus.OK, 'Users.', items.map(toUserResponse), meta);
});

export const createByAdmin = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const user = await usersService.createByAdmin(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'User created.', toUserResponse(user));
});

export const getOne = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const user = await usersService.getOne(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'User found.', toUserResponse(user));
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const user = await usersService.update(ctx, req.params.id, req.body);
  sendSuccess(res, HttpStatus.OK, 'User updated.', toUserResponse(user));
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await usersService.remove(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'User removed.', null);
});
