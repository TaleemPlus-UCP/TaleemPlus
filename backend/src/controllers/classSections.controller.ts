import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { classSectionsService } from '../services/classSections.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { toSectionResponse } from '../utils/serializers';

function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { adminId: req.user.id, academyId: req.user.academyId };
}

export const list = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { className } = req.query as { className?: string };
  const sections = await classSectionsService.list(ctx, className);
  sendSuccess(res, HttpStatus.OK, 'Class sections.', sections.map(toSectionResponse));
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const section = await classSectionsService.create(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'Class section created.', toSectionResponse(section));
});

export const updateEnrollment = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { studentIds } = req.body as { studentIds: string[] };
  const section = await classSectionsService.updateEnrollment(ctx, req.params.id, studentIds);
  sendSuccess(res, HttpStatus.OK, 'Enrollment updated.', toSectionResponse(section));
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await classSectionsService.remove(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Class section deleted.', null);
});
