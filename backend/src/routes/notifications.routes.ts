import { Router } from 'express';
import * as controller from '../controllers/notifications.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import { notificationListQuerySchema } from '../validators/notification.validators';

export const notificationsRouter = Router();

notificationsRouter.use(authenticate, requireActiveAccount);

/**
 * @openapi
 * /notifications:
 *   get:
 *     summary: List the current user's own notifications
 *     tags: [Notifications]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *       - in: query
 *         name: unreadOnly
 *         schema: { type: boolean, default: false }
 *     responses:
 *       200: { description: Paginated list, newest first. }
 */
notificationsRouter.get('/', validate({ query: notificationListQuerySchema }), controller.list);

/**
 * @openapi
 * /notifications/unread-count:
 *   get:
 *     summary: Count of the current user's unread notifications (for a badge)
 *     tags: [Notifications]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: "{ count: number }" }
 */
notificationsRouter.get('/unread-count', controller.unreadCount);

/**
 * @openapi
 * /notifications/mark-all-read:
 *   post:
 *     summary: Mark every one of the current user's notifications as read
 *     tags: [Notifications]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Done. }
 */
notificationsRouter.post('/mark-all-read', controller.markAllRead);

/**
 * @openapi
 * /notifications/{id}/read:
 *   patch:
 *     summary: Mark one of the current user's own notifications as read
 *     tags: [Notifications]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Notification marked as read. }
 *       404: { description: Notification not found (or not yours). }
 */
notificationsRouter.patch('/:id/read', validate({ params: idParamSchema }), controller.markRead);
