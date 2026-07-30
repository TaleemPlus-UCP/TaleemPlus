import { AUDIT_ACTIONS } from '../constants/roles';
import { NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { ocrDocumentRepository } from '../repositories/ocrDocument.repository';
import { buildPaginationMeta } from '../utils/apiResponse';

interface ActorContext {
  userId: string;
}

interface Pagination {
  page: number;
  limit: number;
}

async function create(ctx: ActorContext, title: string, extractedText: string) {
  const doc = await ocrDocumentRepository.create(ctx.userId, title, extractedText);
  await auditLogRepository.record({ userId: ctx.userId, action: AUDIT_ACTIONS.OCR_DOCUMENT_CREATED, metadata: { documentId: doc.id } });
  return doc;
}

async function list(ctx: ActorContext, pagination: Pagination) {
  const { items, total } = await ocrDocumentRepository.findManyByOwner(ctx.userId, pagination);
  return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
}

async function getOne(ctx: ActorContext, id: string) {
  const doc = await ocrDocumentRepository.findByIdAndOwner(id, ctx.userId);
  if (!doc) throw new NotFoundError('Document not found.');
  return doc;
}

interface UpdateInput {
  title?: string;
  extractedText?: string;
}

async function update(ctx: ActorContext, id: string, input: UpdateInput) {
  const doc = await ocrDocumentRepository.findByIdAndOwner(id, ctx.userId);
  if (!doc) throw new NotFoundError('Document not found.');

  const updated = await ocrDocumentRepository.update(id, input);
  await auditLogRepository.record({ userId: ctx.userId, action: AUDIT_ACTIONS.OCR_DOCUMENT_UPDATED, metadata: { documentId: id } });
  return updated;
}

async function remove(ctx: ActorContext, id: string) {
  const doc = await ocrDocumentRepository.findByIdAndOwner(id, ctx.userId);
  if (!doc) throw new NotFoundError('Document not found.');

  await ocrDocumentRepository.delete(id);
  await auditLogRepository.record({ userId: ctx.userId, action: AUDIT_ACTIONS.OCR_DOCUMENT_DELETED, metadata: { documentId: id } });
}

export const ocrDocumentsService = {
  create,
  list,
  getOne,
  update,
  remove,
};
