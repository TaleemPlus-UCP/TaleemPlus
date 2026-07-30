import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { classOfferingsService } from '../services/classOfferings.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { toOfferingResponse } from '../utils/serializers';

function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { userId: req.user.id, academyId: req.user.academyId, role: req.user.role };
}

export const list = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { sectionId } = req.query as { sectionId?: string };
  const offerings = await classOfferingsService.list(ctx, sectionId);
  sendSuccess(res, HttpStatus.OK, 'Classes.', offerings.map(toOfferingResponse));
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const offering = await classOfferingsService.create(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'Class created.', toOfferingResponse(offering));
});

export const getOne = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const offering = await classOfferingsService.getOne(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Class found.', toOfferingResponse(offering));
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const offering = await classOfferingsService.update(ctx, req.params.id, req.body);
  sendSuccess(res, HttpStatus.OK, 'Class updated.', toOfferingResponse(offering));
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await classOfferingsService.remove(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Class deleted.', null);
});
