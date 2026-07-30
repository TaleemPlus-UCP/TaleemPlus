import { Router } from 'express';
import * as controller from '../controllers/learningResources.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import { createLearningResourceSchema, offeringQuerySchema } from '../validators/classroom.validators';

export const learningResourcesRouter = Router();

learningResourcesRouter.use(authenticate, requireActiveAccount);

/**
 * @openapi
 * /learning-resources:
 *   get:
 *     summary: List notes/links shared with one class offering — admin sees any, teacher only their own offerings, student only offerings they're enrolled in
 *     tags: [Classroom]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: offeringId
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Resources, newest first. }
 *   post:
 *     summary: Share a note/link with a class offering (staff only)
 *     tags: [Classroom]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [offeringId, title]
 *             properties:
 *               offeringId: { type: string, format: uuid }
 *               title: { type: string }
 *               description: { type: string }
 *               linkUrl: { type: string, format: uri }
 *     responses:
 *       201: { description: Resource posted. }
 */
learningResourcesRouter
  .route('/')
  .get(validate({ query: offeringQuerySchema }), controller.list)
  .post(validate({ body: createLearningResourceSchema }), controller.create);

/**
 * @openapi
 * /learning-resources/{id}:
 *   delete:
 *     summary: Delete a resource (the posting teacher, or admin)
 *     tags: [Classroom]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Resource deleted. }
 *       404: { description: Resource not found in your academy. }
 */
learningResourcesRouter.delete('/:id', validate({ params: idParamSchema }), controller.remove);
