import { Router } from 'express';
import * as controller from '../controllers/timetable.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import { createSlotSchema, listSlotsQuerySchema, updateSlotSchema } from '../validators/timetable.validators';

export const timetableRouter = Router();

timetableRouter.use(authenticate, requireActiveAccount);

/**
 * @openapi
 * /timetable:
 *   get:
 *     summary: List timetable slots — admin sees the whole academy, teacher sees their own, student sees their enrolled sections, parent must pass studentId for a linked child
 *     tags: [Timetable]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: dayOfWeek
 *         schema: { type: integer, minimum: 1, maximum: 7 }
 *       - in: query
 *         name: studentId
 *         schema: { type: string, format: uuid }
 *         description: Required for PARENT accounts; must be a linked child.
 *     responses:
 *       200: { description: List of timetable slots, sorted by day then start time. }
 *   post:
 *     summary: Create a timetable slot (admin only) — either a class slot (offeringId) or a break (isBreak true)
 *     tags: [Timetable]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [dayOfWeek, startMinutes, endMinutes, effectiveFrom]
 *             properties:
 *               isBreak: { type: boolean, default: false }
 *               offeringId: { type: string, format: uuid }
 *               dayOfWeek: { type: integer, minimum: 1, maximum: 7 }
 *               startMinutes: { type: integer }
 *               endMinutes: { type: integer }
 *               room: { type: string }
 *               semester: { type: string }
 *               effectiveFrom: { type: string, format: date }
 *               effectiveTo: { type: string, format: date }
 *     responses:
 *       201: { description: Slot created. }
 *       409: { description: Conflicts with an existing teacher/room/section booking at that time. }
 */
timetableRouter
  .route('/')
  .get(validate({ query: listSlotsQuerySchema }), controller.list)
  .post(requireRoles('ADMIN'), validate({ body: createSlotSchema }), controller.create);

/**
 * @openapi
 * /timetable/{id}:
 *   patch:
 *     summary: Update a timetable slot (admin only)
 *     tags: [Timetable]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Slot updated. }
 *       404: { description: Slot not found in your academy. }
 *       409: { description: Conflicts with an existing teacher/room/section booking at that time. }
 *   delete:
 *     summary: Delete a timetable slot (admin only)
 *     tags: [Timetable]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Slot deleted. }
 *       404: { description: Slot not found in your academy. }
 */
timetableRouter
  .route('/:id')
  .patch(requireRoles('ADMIN'), validate({ params: idParamSchema, body: updateSlotSchema }), controller.update)
  .delete(requireRoles('ADMIN'), validate({ params: idParamSchema }), controller.remove);
