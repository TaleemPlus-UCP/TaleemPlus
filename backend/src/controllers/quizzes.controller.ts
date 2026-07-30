import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { quizzesService } from '../services/quizzes.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { toQuizResponse } from '../utils/serializers';

function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { userId: req.user.id, academyId: req.user.academyId, role: req.user.role };
}

export const create = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const quiz = await quizzesService.create(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'Quiz created.', toQuizResponse(quiz));
});

export const list = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { page, limit, offeringId } = req.query as unknown as { page: number; limit: number; offeringId?: string };
  const { items, meta } = await quizzesService.list(ctx, { offeringId }, { page, limit });
  sendSuccess(res, HttpStatus.OK, 'Quizzes.', items.map(toQuizResponse), meta);
});

export const getOne = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const quiz = await quizzesService.getOne(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Quiz found.', toQuizResponse(quiz));
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const quiz = await quizzesService.update(ctx, req.params.id, req.body);
  sendSuccess(res, HttpStatus.OK, 'Quiz updated.', toQuizResponse(quiz));
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await quizzesService.remove(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Quiz deleted.', null);
});

export const gradeSuggestion = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const result = await quizzesService.gradeSuggestion(ctx, req.params.id, req.params.questionId, req.body.ocrText);
  sendSuccess(res, HttpStatus.OK, 'Grade suggestion computed.', result);
});
