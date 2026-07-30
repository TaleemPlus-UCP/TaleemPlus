import { Router } from 'express';
import * as controller from '../controllers/attendance.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import {
  daySheetQuerySchema,
  markSheetSchema,
  monthlyQuerySchema,
  yearlyQuerySchema,
} from '../validators/attendance.validators';
import { z } from 'zod';

export const attendanceRouter = Router();

attendanceRouter.use(authenticate, requireActiveAccount);

const studentIdParamSchema = z.object({ studentId: idParamSchema.shape.id });

/**
 * @openapi
 * /attendance:
 *   post:
 *     summary: Save (upsert) a full day's attendance sheet for a class offering (admin/teacher only)
 *     tags: [Attendance]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [offeringId, logDate, records]
 *             properties:
 *               offeringId: { type: string, format: uuid }
 *               logDate: { type: string, format: date }
 *               records:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required: [studentId, status]
 *                   properties:
 *                     studentId: { type: string, format: uuid }
 *                     status: { type: string, enum: [PRESENT, ABSENT, LATE] }
 *     responses:
 *       200: { description: Attendance saved; returns the full resulting day sheet. }
 *       400: { description: One or more students are not enrolled in this class section. }
 *       404: { description: Class not found in your academy. }
 *   get:
 *     summary: Get a class offering's attendance sheet for one day (admin/teacher only)
 *     tags: [Attendance]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: offeringId
 *         required: true
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: logDate
 *         required: true
 *         schema: { type: string, format: date }
 *     responses:
 *       200: { description: Day sheet, with every enrolled student defaulted to ABSENT unless already marked. }
 *       404: { description: Class not found in your academy. }
 */
attendanceRouter
  .route('/')
  .post(requireRoles('ADMIN', 'TEACHER'), validate({ body: markSheetSchema }), controller.markSheet)
  .get(requireRoles('ADMIN', 'TEACHER'), validate({ query: daySheetQuerySchema }), controller.getDaySheet);

/**
 * @openapi
 * /attendance/students/{studentId}/monthly:
 *   get:
 *     summary: One student's daily attendance + summary for a specific month (defaults to the current month)
 *     tags: [Attendance]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: studentId
 *         required: true
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: year
 *         schema: { type: integer }
 *       - in: query
 *         name: month
 *         schema: { type: integer, minimum: 1, maximum: 12 }
 *     responses:
 *       200: { description: Daily records for the month plus present/absent/late counts and percentage. }
 *       403: { description: Not authorized to view this student's attendance. }
 *       404: { description: Student not found (or outside your academy). }
 */
attendanceRouter.get(
  '/students/:studentId/monthly',
  validate({ params: studentIdParamSchema, query: monthlyQuerySchema }),
  controller.getStudentMonthly,
);

/**
 * @openapi
 * /attendance/students/{studentId}/yearly:
 *   get:
 *     summary: One student's month-by-month attendance summary for a whole year (defaults to the current year)
 *     tags: [Attendance]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: studentId
 *         required: true
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: year
 *         schema: { type: integer }
 *     responses:
 *       200: { description: 12 monthly summaries (present/absent/late counts and percentage each). }
 *       403: { description: Not authorized to view this student's attendance. }
 *       404: { description: Student not found (or outside your academy). }
 */
attendanceRouter.get(
  '/students/:studentId/yearly',
  validate({ params: studentIdParamSchema, query: yearlyQuerySchema }),
  controller.getStudentYearly,
);
