import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { attendanceService } from '../services/attendance.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { userId: req.user.id, academyId: req.user.academyId, role: req.user.role };
}

export const markSheet = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { offeringId, logDate, records } = req.body;
  const sheet = await attendanceService.markSheet(ctx, offeringId, logDate, records);
  sendSuccess(res, HttpStatus.OK, 'Attendance saved.', sheet);
});

export const getDaySheet = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { offeringId, logDate } = req.query as unknown as { offeringId: string; logDate: Date };
  const sheet = await attendanceService.getDaySheet(ctx, offeringId, logDate);
  sendSuccess(res, HttpStatus.OK, 'Attendance sheet.', sheet);
});

export const getStudentMonthly = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { year, month } = req.query as unknown as { year?: number; month?: number };
  const result = await attendanceService.getStudentMonthly(ctx, req.params.studentId, year, month);
  sendSuccess(res, HttpStatus.OK, 'Monthly attendance.', result);
});

export const getStudentYearly = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { year } = req.query as unknown as { year?: number };
  const result = await attendanceService.getStudentYearly(ctx, req.params.studentId, year);
  sendSuccess(res, HttpStatus.OK, 'Yearly attendance.', result);
});
