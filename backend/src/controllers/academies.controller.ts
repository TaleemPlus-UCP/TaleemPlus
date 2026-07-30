import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { academiesService } from '../services/academies.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { userId: req.user.id, academyId: req.user.academyId, role: req.user.role };
}

export const updateMine = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const academy = await academiesService.updateMine(ctx, req.body);
  sendSuccess(res, HttpStatus.OK, 'Academy updated.', academy);
});
