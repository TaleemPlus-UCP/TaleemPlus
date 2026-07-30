import { Router } from 'express';
import * as controller from '../controllers/announcements.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import {
  announcementListQuerySchema,
  createAnnouncementSchema,
  updateAnnouncementSchema,
} from '../validators/announcement.validators';

export const announcementsRouter = Router();

announcementsRouter.use(authenticate, requireActiveAccount);

/**
 * @openapi
 * /announcements:
 *   get:
 *     summary: List announcements — admins see every announcement in the academy, other roles see only what targets them
 *     tags: [Announcements]
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
 *     summary: Post a new announcement (admin/teacher only) — fans out an in-app notification to every targeted, ACTIVE user
 *     tags: [Announcements]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [title, message]
 *             properties:
 *               title: { type: string }
 *               message: { type: string }
 *               isForAll: { type: boolean, default: false }
 *               targetRoles:
 *                 type: array
 *                 items: { type: string, enum: [TEACHER, STUDENT, PARENT] }
 *     responses:
 *       201: { description: Announcement created. }
 *       422: { description: targetRoles must be non-empty unless isForAll is true. }
 */
announcementsRouter
  .route('/')
  .get(validate({ query: announcementListQuerySchema }), controller.list)
  .post(requireRoles('ADMIN', 'TEACHER'), validate({ body: createAnnouncementSchema }), controller.create);

/**
 * @openapi
 * /announcements/{id}:
 *   patch:
 *     summary: Update an announcement (admin/teacher only)
 *     tags: [Announcements]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Announcement updated. }
 *       404: { description: Announcement not found in your academy. }
 *   delete:
 *     summary: Delete an announcement (admin/teacher only)
 *     tags: [Announcements]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Announcement deleted. }
 *       404: { description: Announcement not found in your academy. }
 */
announcementsRouter
  .route('/:id')
  .patch(requireRoles('ADMIN', 'TEACHER'), validate({ params: idParamSchema, body: updateAnnouncementSchema }), controller.update)
  .delete(requireRoles('ADMIN', 'TEACHER'), validate({ params: idParamSchema }), controller.remove);
