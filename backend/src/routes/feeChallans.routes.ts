import { Router } from 'express';
import * as controller from '../controllers/feeChallans.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import {
  createChallanSchema,
  generateChallansSchema,
  listChallansQuerySchema,
  sectionStatusQuerySchema,
  updateChallanStatusSchema,
} from '../validators/feeChallan.validators';
import { z } from 'zod';

export const feeChallansRouter = Router();

feeChallansRouter.use(authenticate, requireActiveAccount);

const sectionIdParamSchema = z.object({ sectionId: idParamSchema.shape.id });

/**
 * @openapi
 * /fee-challans/generate:
 *   post:
 *     summary: Batch-generate a challan for every ACTIVE student enrolled in a section for one billing month (admin only) — students already billed for that month are skipped
 *     tags: [Fees]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [sectionId, billingYear, billingMonth, monthlyFee]
 *             properties:
 *               sectionId: { type: string, format: uuid }
 *               billingYear: { type: integer }
 *               billingMonth: { type: integer, minimum: 1, maximum: 12 }
 *               monthlyFee: { type: number }
 *               admissionFee: { type: number, default: 0 }
 *               examFee: { type: number, default: 0 }
 *               transportFee: { type: number, default: 0 }
 *               fine: { type: number, default: 0 }
 *               dueDate: { type: string, format: date }
 *     responses:
 *       201: { description: "{ generatedCount, skippedCount, eligibleCount }" }
 *       400: { description: No ACTIVE students enrolled in this section. }
 *       404: { description: Section not found in your academy. }
 */
feeChallansRouter.post(
  '/generate',
  requireRoles('ADMIN'),
  validate({ body: generateChallansSchema }),
  controller.generate,
);

/**
 * @openapi
 * /fee-challans/sections/{sectionId}/status:
 *   get:
 *     summary: Fee status for every enrolled student in a section for one month (admin only) — powers a class-wide fee status view
 *     tags: [Fees]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: sectionId
 *         required: true
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: year
 *         schema: { type: integer }
 *       - in: query
 *         name: month
 *         schema: { type: integer, minimum: 1, maximum: 12 }
 *     responses:
 *       200: { description: Every enrolled student with their challan for that month, or null if not yet generated. }
 *       404: { description: Section not found in your academy. }
 */
feeChallansRouter.get(
  '/sections/:sectionId/status',
  requireRoles('ADMIN'),
  validate({ params: sectionIdParamSchema, query: sectionStatusQuerySchema }),
  controller.getSectionStatus,
);

/**
 * @openapi
 * /fee-challans:
 *   get:
 *     summary: List fee challans — admins see the academy (optionally filtered by studentId), students see only their own, parents must pass studentId for a linked child
 *     tags: [Fees]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: studentId
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: billingYear
 *         schema: { type: integer }
 *       - in: query
 *         name: billingMonth
 *         schema: { type: integer }
 *       - in: query
 *         name: status
 *         schema: { type: string, enum: [PENDING, PAID, OVERDUE] }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200: { description: Paginated list, newest billing period first. }
 *       403: { description: Teachers have no access to fee challans, or a parent queried an unlinked student. }
 *   post:
 *     summary: Create one ad-hoc fee challan for a single student (admin only), independent of section-wide billing
 *     tags: [Fees]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [studentId, billingYear, billingMonth, monthlyFee]
 *             properties:
 *               studentId: { type: string, format: uuid }
 *               billingYear: { type: integer }
 *               billingMonth: { type: integer, minimum: 1, maximum: 12 }
 *               monthlyFee: { type: number }
 *               admissionFee: { type: number, default: 0 }
 *               examFee: { type: number, default: 0 }
 *               transportFee: { type: number, default: 0 }
 *               fine: { type: number, default: 0 }
 *               dueDate: { type: string, format: date }
 *     responses:
 *       201: { description: Challan created. }
 *       400: { description: studentId is not an ACTIVE student in your academy. }
 *       409: { description: This student already has a fee challan for that billing month. }
 */
feeChallansRouter
  .route('/')
  .get(validate({ query: listChallansQuerySchema }), controller.list)
  .post(requireRoles('ADMIN'), validate({ body: createChallanSchema }), controller.createOne);

/**
 * @openapi
 * /fee-challans/{id}:
 *   get:
 *     summary: Get one fee challan (admin, the billed student, or a linked parent)
 *     tags: [Fees]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Challan found. }
 *       404: { description: Not found (or not visible to you). }
 */
feeChallansRouter.get('/:id', validate({ params: idParamSchema }), controller.getOne);

/**
 * @openapi
 * /fee-challans/{id}/status:
 *   patch:
 *     summary: Update a challan's payment status (admin only)
 *     tags: [Fees]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [status]
 *             properties:
 *               status: { type: string, enum: [PENDING, PAID, OVERDUE] }
 *     responses:
 *       200: { description: Status updated. }
 *       404: { description: Challan not found in your academy. }
 */
feeChallansRouter.patch(
  '/:id/status',
  requireRoles('ADMIN'),
  validate({ params: idParamSchema, body: updateChallanStatusSchema }),
  controller.updateStatus,
);
