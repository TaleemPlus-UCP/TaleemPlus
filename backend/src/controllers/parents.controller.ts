import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { parentsService } from '../services/parents.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { toUserResponse } from '../utils/serializers';

function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { userId: req.user.id, academyId: req.user.academyId, role: req.user.role };
}

export const listChildren = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const children = await parentsService.listChildren(ctx);
  sendSuccess(res, HttpStatus.OK, 'Linked children.', children.map(toUserResponse));
});

export const linkChild = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const student = await parentsService.linkChild(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'Child linked.', toUserResponse(student));
});

export const unlinkChild = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await parentsService.unlinkChild(ctx, req.params.childId);
  sendSuccess(res, HttpStatus.OK, 'Child unlinked.', null);
});

export const searchStudents = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { query, page, limit } = req.query as unknown as { query: string; page: number; limit: number };
  const { items, meta } = await parentsService.searchStudents(ctx, query, { page, limit });
  sendSuccess(res, HttpStatus.OK, 'Students.', items.map(toUserResponse), meta);
});
