import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { announcementsService } from '../services/announcements.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { userId: req.user.id, academyId: req.user.academyId, role: req.user.role };
}

export const list = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { page, limit } = req.query as unknown as { page: number; limit: number };
  const { items, meta } = await announcementsService.list(ctx, { page, limit });
  sendSuccess(res, HttpStatus.OK, 'Announcements.', items, meta);
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const announcement = await announcementsService.create(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'Announcement created.', announcement);
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const announcement = await announcementsService.update(ctx, req.params.id, req.body);
  sendSuccess(res, HttpStatus.OK, 'Announcement updated.', announcement);
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await announcementsService.remove(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Announcement deleted.', null);
});
