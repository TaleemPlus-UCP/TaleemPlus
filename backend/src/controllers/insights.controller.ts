import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { insightsService } from '../services/insights.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

function requireAcademyId(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return req.user.academyId;
}

export const atRiskStudents = asyncHandler(async (req: Request, res: Response) => {
  const academyId = requireAcademyId(req);
  const result = await insightsService.getAtRiskStudents(academyId);
  sendSuccess(res, HttpStatus.OK, 'At-risk student insights.', result);
});

export const revenueForecast = asyncHandler(async (req: Request, res: Response) => {
  const academyId = requireAcademyId(req);
  const result = await insightsService.getRevenueForecast(academyId);
  sendSuccess(res, HttpStatus.OK, 'Revenue forecast.', result);
});
