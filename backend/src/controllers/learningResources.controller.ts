import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { learningResourcesService } from '../services/learningResources.service';
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
  const { offeringId } = req.query as unknown as { offeringId: string };
  const items = await learningResourcesService.list(ctx, offeringId);
  sendSuccess(res, HttpStatus.OK, 'Learning resources.', items);
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const resource = await learningResourcesService.create(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'Resource posted.', resource);
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await learningResourcesService.remove(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Resource deleted.', null);
});
