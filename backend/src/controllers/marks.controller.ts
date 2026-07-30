import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { marksService } from '../services/marks.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { toTestMarkResponse } from '../utils/serializers';

function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { userId: req.user.id, academyId: req.user.academyId, role: req.user.role };
}

export const upsertMarks = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const marks = await marksService.upsertMarks(ctx, req.params.quizId, req.body.records);
  sendSuccess(res, HttpStatus.OK, 'Marks saved.', marks.map(toTestMarkResponse));
});

export const listForQuiz = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const marks = await marksService.listForQuiz(ctx, req.params.quizId);
  sendSuccess(res, HttpStatus.OK, 'Marks.', marks.map(toTestMarkResponse));
});

export const listForStudent = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { page, limit, subject, year, month } = req.query as unknown as {
    page: number;
    limit: number;
    subject?: string;
    year?: number;
    month?: number;
  };
  const { items, meta } = await marksService.listForStudent(ctx, req.params.studentId, { subject, year, month }, { page, limit });
  sendSuccess(res, HttpStatus.OK, 'Student marks.', items.map(toTestMarkResponse), meta);
});

export const deleteMark = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await marksService.deleteMark(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Mark deleted.', null);
});
