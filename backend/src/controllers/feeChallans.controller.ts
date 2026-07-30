import { Request, Response } from 'express';
import { FeeChallanStatus } from '@prisma/client';
import { HttpStatus } from '../constants/httpStatus';
import { ForbiddenError } from '../exceptions/AppError';
import { feeChallansService } from '../services/feeChallans.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { toFeeChallanResponse } from '../utils/serializers';

function requireActorContext(req: Request) {
  if (!req.user?.academyId) {
    throw new ForbiddenError('Your account has no associated academy.');
  }
  return { userId: req.user.id, academyId: req.user.academyId, role: req.user.role };
}

export const generate = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const result = await feeChallansService.generate(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'Fee challans generated.', result);
});

export const createOne = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const challan = await feeChallansService.createOne(ctx, req.body);
  sendSuccess(res, HttpStatus.CREATED, 'Fee challan created.', toFeeChallanResponse(challan));
});

export const list = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { page, limit, studentId, billingYear, billingMonth, status } = req.query as unknown as {
    page: number;
    limit: number;
    studentId?: string;
    billingYear?: number;
    billingMonth?: number;
    status?: FeeChallanStatus;
  };
  const { items, meta } = await feeChallansService.list(ctx, { studentId, billingYear, billingMonth, status }, { page, limit });
  sendSuccess(res, HttpStatus.OK, 'Fee challans.', items.map(toFeeChallanResponse), meta);
});

export const getOne = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const challan = await feeChallansService.getOne(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Fee challan found.', toFeeChallanResponse(challan));
});

export const updateStatus = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const challan = await feeChallansService.updateStatus(ctx, req.params.id, req.body.status);
  sendSuccess(res, HttpStatus.OK, 'Fee challan status updated.', toFeeChallanResponse(challan));
});

export const getSectionStatus = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { year, month } = req.query as unknown as { year?: number; month?: number };
  const result = await feeChallansService.getSectionStatus(ctx, req.params.sectionId, year, month);
  sendSuccess(res, HttpStatus.OK, 'Section fee status.', {
    ...result,
    students: result.students.map((s) => ({
      studentId: s.studentId,
      fullName: s.fullName,
      challan: s.challan ? toFeeChallanResponse(s.challan) : null,
    })),
  });
});
