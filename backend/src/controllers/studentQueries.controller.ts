import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { studentQueriesService } from '../services/studentQueries.service';
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
  const items = await studentQueriesService.list(ctx, offeringId);
  sendSuccess(res, HttpStatus.OK, 'Class questions.', items);
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const query = await studentQueriesService.create(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'Question posted.', query);
});

export const answer = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { answer: answerText } = req.body as { answer: string };
  const query = await studentQueriesService.answer(ctx, req.params.id, answerText);
  sendSuccess(res, HttpStatus.OK, 'Question answered.', query);
});
