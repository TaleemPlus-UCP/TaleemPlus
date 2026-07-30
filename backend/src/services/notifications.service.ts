import { NotificationType } from '@prisma/client';
import { logger } from '../config/logger';
import { NotFoundError } from '../exceptions/AppError';
import { notificationRepository } from '../repositories/notification.repository';
import { buildPaginationMeta } from '../utils/apiResponse';

interface ActorContext {
  userId: string;
}

interface Pagination {
  page: number;
  limit: number;
  unreadOnly: boolean;
}

async function list(ctx: ActorContext, pagination: Pagination) {
  const { items, total } = await notificationRepository.findManyForUser(ctx.userId, pagination);
  return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
}

async function unreadCount(ctx: ActorContext) {
  const count = await notificationRepository.countUnread(ctx.userId);
  return { count };
}

async function markRead(ctx: ActorContext, notificationId: string) {
  const notification = await notificationRepository.findByIdAndRecipient(notificationId, ctx.userId);
  if (!notification) throw new NotFoundError('Notification not found.');
  return notificationRepository.markRead(notificationId);
}

async function markAllRead(ctx: ActorContext) {
  await notificationRepository.markAllRead(ctx.userId);
}

/**
 * Fire-and-forget from the caller's point of view: a notification-delivery
 * failure must never block the action that triggered it (an approval, an
 * announcement post, etc. has already succeeded by the time this runs).
 */
async function notifyUser(
  academyId: string,
  recipientId: string,
  title: string,
  message: string,
  type: NotificationType,
): Promise<void> {
  try {
    await notificationRepository.create({ academyId, recipientId, title, message, type });
  } catch (error) {
    logger.warn(`Failed to create notification for user ${recipientId}: ${(error as Error).message}`);
  }
}

async function notifyMany(
  academyId: string,
  recipientIds: string[],
  title: string,
  message: string,
  type: NotificationType,
): Promise<void> {
  try {
    await notificationRepository.createMany(
      recipientIds.map((recipientId) => ({ academyId, recipientId, title, message, type })),
    );
  } catch (error) {
    logger.warn(`Failed to bulk-create notifications: ${(error as Error).message}`);
  }
}

export const notificationsService = {
  list,
  unreadCount,
  markRead,
  markAllRead,
  notifyUser,
  notifyMany,
};
