import { Router } from 'express';
import { z } from 'zod';
import * as controller from '../controllers/marks.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import { studentMarksQuerySchema } from '../validators/quiz.validators';

export const marksRouter = Router();

marksRouter.use(authenticate, requireActiveAccount);

const studentIdParamSchema = z.object({ studentId: idParamSchema.shape.id });

/**
 * @openapi
 * /marks/students/{studentId}:
 *   get:
 *     summary: A student's own marks (self, staff in the same academy, or a linked parent) — never includes quiz questions/answer key
 *     tags: [Marks]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: studentId
 *         required: true
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: subject
 *         schema: { type: string }
 *       - in: query
 *         name: year
 *         schema: { type: integer }
 *       - in: query
 *         name: month
 *         schema: { type: integer, minimum: 1, maximum: 12 }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200: { description: Paginated marks, newest test date first. }
 *       403: { description: Not authorized to view this student's marks. }
 *       404: { description: Student not found (or outside your academy). }
 */
marksRouter.get(
  '/students/:studentId',
  validate({ params: studentIdParamSchema, query: studentMarksQuerySchema }),
  controller.listForStudent,
);

/**
 * @openapi
 * /marks/{id}:
 *   delete:
 *     summary: Delete a single mark (admin only, mirroring the legacy app's delete-admin-only rule for test_marks)
 *     tags: [Marks]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Mark deleted. }
 *       404: { description: Mark not found. }
 */
marksRouter.delete('/:id', requireRoles('ADMIN'), validate({ params: idParamSchema }), controller.deleteMark);
