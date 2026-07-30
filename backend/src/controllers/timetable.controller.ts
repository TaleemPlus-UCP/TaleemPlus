import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { timetableService } from '../services/timetable.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { toTimetableSlotResponse } from '../utils/serializers';

function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { userId: req.user.id, academyId: req.user.academyId, role: req.user.role };
}

export const create = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const slot = await timetableService.create(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'Timetable slot created.', toTimetableSlotResponse(slot));
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const slot = await timetableService.update(ctx, req.params.id, req.body);
  sendSuccess(res, HttpStatus.OK, 'Timetable slot updated.', toTimetableSlotResponse(slot));
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await timetableService.remove(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Timetable slot deleted.', null);
});

export const list = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { dayOfWeek, studentId } = req.query as unknown as { dayOfWeek?: number; studentId?: string };
  const slots = await timetableService.list(ctx, { dayOfWeek, studentId });
  sendSuccess(res, HttpStatus.OK, 'Timetable.', slots.map(toTimetableSlotResponse));
});
