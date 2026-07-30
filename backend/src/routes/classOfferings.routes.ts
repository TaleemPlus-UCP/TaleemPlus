import { Router } from 'express';
import * as controller from '../controllers/classOfferings.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import {
  createOfferingSchema,
  listOfferingsQuerySchema,
  updateOfferingSchema,
} from '../validators/classOffering.validators';

export const classOfferingsRouter = Router();

classOfferingsRouter.use(authenticate, requireActiveAccount);

/**
 * @openapi
 * /classes:
 *   get:
 *     summary: List subject offerings — admins see the whole academy, teachers see only their own
 *     tags: [Classes]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: sectionId
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: List of class offerings. }
 *   post:
 *     summary: Create a subject offering for a section (admin only)
 *     tags: [Classes]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [sectionId, teacherId]
 *             properties:
 *               sectionId: { type: string, format: uuid }
 *               teacherId: { type: string, format: uuid }
 *               subject: { type: string }
 *     responses:
 *       201: { description: Class created. }
 *       400: { description: teacherId is not an ACTIVE teacher in this academy. }
 *       404: { description: Section not found in your academy. }
 */
classOfferingsRouter
  .route('/')
  .get(requireRoles('ADMIN', 'TEACHER'), validate({ query: listOfferingsQuerySchema }), controller.list)
  .post(requireRoles('ADMIN'), validate({ body: createOfferingSchema }), controller.create);

/**
 * @openapi
 * /classes/{id}:
 *   get:
 *     summary: Get one class offering (admin only)
 *     tags: [Classes]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Class found. }
 *       404: { description: Class not found in your academy. }
 *   patch:
 *     summary: Update a class offering's subject and/or teacher (admin only)
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
 *             properties:
 *               subject: { type: string }
 *               teacherId: { type: string, format: uuid }
 *     responses:
 *       200: { description: Class updated. }
 *       404: { description: Class not found in your academy. }
 *   delete:
 *     summary: Delete a class offering (admin only)
 *     tags: [Classes]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Class deleted. }
 *       404: { description: Class not found in your academy. }
 */
classOfferingsRouter
  .route('/:id')
  .get(requireRoles('ADMIN'), validate({ params: idParamSchema }), controller.getOne)
  .patch(requireRoles('ADMIN'), validate({ params: idParamSchema, body: updateOfferingSchema }), controller.update)
  .delete(requireRoles('ADMIN'), validate({ params: idParamSchema }), controller.remove);
