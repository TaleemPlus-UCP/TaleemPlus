import { NotificationType, Prisma } from '@prisma/client';
import { prisma } from '../config/database';

interface CreateNotificationInput {
  academyId: string;
  recipientId: string;
  title: string;
  message: string;
  type: NotificationType;
}

interface Pagination {
  page: number;
  limit: number;
  unreadOnly: boolean;
}

export const notificationRepository = {
  create(data: CreateNotificationInput) {
    return prisma.notification.create({ data });
  },

  createMany(notifications: CreateNotificationInput[]) {
    if (notifications.length === 0) return Promise.resolve({ count: 0 });
    return prisma.notification.createMany({ data: notifications });
  },

  async findManyForUser(recipientId: string, { page, limit, unreadOnly }: Pagination) {
    const where: Prisma.NotificationWhereInput = { recipientId, ...(unreadOnly ? { isRead: false } : {}) };
    const [items, total] = await Promise.all([
      prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.notification.count({ where }),
    ]);
    return { items, total };
  },

  countUnread(recipientId: string) {
    return prisma.notification.count({ where: { recipientId, isRead: false } });
  },

  findByIdAndRecipient(id: string, recipientId: string) {
    return prisma.notification.findFirst({ where: { id, recipientId } });
  },

  markRead(id: string) {
    return prisma.notification.update({ where: { id }, data: { isRead: true } });
  },

  markAllRead(recipientId: string) {
    return prisma.notification.updateMany({ where: { recipientId, isRead: false }, data: { isRead: true } });
  },
};
