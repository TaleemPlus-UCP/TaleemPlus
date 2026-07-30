import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { UnauthorizedError } from '../exceptions/AppError';
import { ocrDocumentsService } from '../services/ocrDocuments.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

function requireActorContext(req: Request) {
  if (!req.user) throw new UnauthorizedError('Authentication required.');
  return { userId: req.user.id };
}

export const create = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const doc = await ocrDocumentsService.create(ctx, req.body.title, req.body.extractedText);
  sendSuccess(res, HttpStatus.CREATED, 'Document saved.', doc);
});

export const list = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { page, limit } = req.query as unknown as { page: number; limit: number };
  const { items, meta } = await ocrDocumentsService.list(ctx, { page, limit });
  sendSuccess(res, HttpStatus.OK, 'Documents.', items, meta);
});

export const getOne = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const doc = await ocrDocumentsService.getOne(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Document found.', doc);
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const doc = await ocrDocumentsService.update(ctx, req.params.id, req.body);
  sendSuccess(res, HttpStatus.OK, 'Document updated.', doc);
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await ocrDocumentsService.remove(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Document deleted.', null);
});
