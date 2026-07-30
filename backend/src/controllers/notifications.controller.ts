import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { UnauthorizedError } from '../exceptions/AppError';
import { notificationsService } from '../services/notifications.service';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

function requireActorContext(req: Request) {
  if (!req.user) throw new UnauthorizedError('Authentication required.');
  return { userId: req.user.id };
}

export const list = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const { page, limit, unreadOnly } = req.query as unknown as { page: number; limit: number; unreadOnly: boolean };
  const { items, meta } = await notificationsService.list(ctx, { page, limit, unreadOnly });
  sendSuccess(res, HttpStatus.OK, 'Notifications.', items, meta);
});

export const unreadCount = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const result = await notificationsService.unreadCount(ctx);
  sendSuccess(res, HttpStatus.OK, 'Unread notification count.', result);
});

export const markRead = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  const notification = await notificationsService.markRead(ctx, req.params.id);
  sendSuccess(res, HttpStatus.OK, 'Notification marked as read.', notification);
});

export const markAllRead = asyncHandler(async (req: Request, res: Response) => {
  const ctx = requireActorContext(req);
  await notificationsService.markAllRead(ctx);
  sendSuccess(res, HttpStatus.OK, 'All notifications marked as read.', null);
});
