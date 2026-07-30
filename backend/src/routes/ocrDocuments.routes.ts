import { Router } from 'express';
import * as controller from '../controllers/ocrDocuments.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema, paginationQuerySchema } from '../validators/common.validators';
import { createOcrDocumentSchema, updateOcrDocumentSchema } from '../validators/ocrDocument.validators';

export const ocrDocumentsRouter = Router();

// Owner-scoped for every role — no academy filtering, matching the legacy app's deliberate design.
ocrDocumentsRouter.use(authenticate, requireActiveAccount);

/**
 * @openapi
 * /ocr-documents:
 *   get:
 *     summary: List the current user's own scanned/OCR'd documents
 *     tags: [OCR]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200: { description: Paginated list, newest first. }
 *   post:
 *     summary: Save a new OCR'd document (the OCR itself runs on-device via Flutter/ML Kit; this endpoint just persists the result)
 *     tags: [OCR]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [title, extractedText]
 *             properties:
 *               title: { type: string }
 *               extractedText: { type: string }
 *     responses:
 *       201: { description: Document saved. }
 */
ocrDocumentsRouter
  .route('/')
  .get(validate({ query: paginationQuerySchema }), controller.list)
  .post(validate({ body: createOcrDocumentSchema }), controller.create);

/**
 * @openapi
 * /ocr-documents/{id}:
 *   get:
 *     summary: Get one of the current user's own documents
 *     tags: [OCR]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Document found. }
 *       404: { description: Not found (or not yours). }
 *   patch:
 *     summary: Update the title/text of one of the current user's own documents
 *     tags: [OCR]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Document updated. }
 *       404: { description: Not found (or not yours). }
 *   delete:
 *     summary: Delete one of the current user's own documents
 *     tags: [OCR]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Document deleted. }
 *       404: { description: Not found (or not yours). }
 */
ocrDocumentsRouter
  .route('/:id')
  .get(validate({ params: idParamSchema }), controller.getOne)
  .patch(validate({ params: idParamSchema, body: updateOcrDocumentSchema }), controller.update)
  .delete(validate({ params: idParamSchema }), controller.remove);
