import { Router } from 'express';
import * as controller from '../controllers/classSections.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import {
  createSectionSchema,
  listSectionsQuerySchema,
  updateEnrollmentSchema,
} from '../validators/classSection.validators';

export const classSectionsRouter = Router();

// Every route in this module is admin-only and scoped to the admin's own academy.
classSectionsRouter.use(authenticate, requireActiveAccount, requireRoles('ADMIN'));

/**
 * @openapi
 * /class-sections:
 *   get:
 *     summary: List class sections (e.g. "10th - A") in the admin's academy
 *     tags: [Classes]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: className
 *         schema: { type: string }
 *     responses:
 *       200: { description: List of sections with enrolled studentIds and counts. }
 *   post:
 *     summary: Create a class section
 *     tags: [Classes]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [className, sectionLabel]
 *             properties:
 *               className: { type: string }
 *               sectionLabel: { type: string }
 *     responses:
 *       201: { description: Section created. }
 *       409: { description: A section with this className+sectionLabel already exists in this academy. }
 */
classSectionsRouter
  .route('/')
  .get(validate({ query: listSectionsQuerySchema }), controller.list)
  .post(validate({ body: createSectionSchema }), controller.create);

/**
 * @openapi
 * /class-sections/{id}/enrollment:
 *   put:
 *     summary: Replace the section's full student roster (every subject offering under it shares this roster)
 *     tags: [Classes]
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
 *             required: [studentIds]
 *             properties:
 *               studentIds: { type: array, items: { type: string, format: uuid } }
 *     responses:
 *       200: { description: Enrollment updated. }
 *       400: { description: One or more ids are not ACTIVE students in this academy. }
 *       404: { description: Section not found in your academy. }
 */
classSectionsRouter.put(
  '/:id/enrollment',
  validate({ params: idParamSchema, body: updateEnrollmentSchema }),
  controller.updateEnrollment,
);

/**
 * @openapi
 * /class-sections/{id}:
 *   delete:
 *     summary: Delete a section (cascades to its enrollments and every subject offering under it)
 *     tags: [Classes]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Section deleted. }
 *       404: { description: Section not found in your academy. }
 */
classSectionsRouter.delete('/:id', validate({ params: idParamSchema }), controller.remove);
