import { Router } from 'express';
import * as controller from '../controllers/parents.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { childIdParamSchema, linkChildSchema, searchStudentsQuerySchema } from '../validators/parent.validators';

export const parentsRouter = Router();

// Every route here is parent-only and scoped to the caller's own academy.
parentsRouter.use(authenticate, requireActiveAccount, requireRoles('PARENT'));

/**
 * @openapi
 * /parents/children:
 *   get:
 *     summary: List the caller's linked children
 *     tags: [Parents]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Linked children profiles. }
 *   post:
 *     summary: Link a child by exact email or by studentId (from a search result)
 *     tags: [Parents]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email: { type: string, format: email }
 *               studentId: { type: string, format: uuid }
 *     responses:
 *       201: { description: Child linked. }
 *       404: { description: No such student in your academy. }
 *       409: { description: Already linked. }
 */
parentsRouter
  .route('/children')
  .get(controller.listChildren)
  .post(validate({ body: linkChildSchema }), controller.linkChild);

/**
 * @openapi
 * /parents/children/{childId}:
 *   delete:
 *     summary: Unlink a child
 *     tags: [Parents]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: childId
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Child unlinked. }
 *       404: { description: Not linked. }
 */
parentsRouter.delete('/children/:childId', validate({ params: childIdParamSchema }), controller.unlinkChild);

/**
 * @openapi
 * /parents/students/search:
 *   get:
 *     summary: Search students by name/email/phone within the caller's academy (for picking a child to link)
 *     tags: [Parents]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: query
 *         required: true
 *         schema: { type: string }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200: { description: Paginated list of matching students. }
 */
parentsRouter.get('/students/search', validate({ query: searchStudentsQuerySchema }), controller.searchStudents);
