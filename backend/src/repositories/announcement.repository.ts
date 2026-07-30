import { Prisma, UserRole } from '@prisma/client';
import { prisma } from '../config/database';

const withCreator = {
  createdBy: { select: { id: true, fullName: true } },
} satisfies Prisma.AnnouncementInclude;

interface Pagination {
  page: number;
  limit: number;
}

export const announcementRepository = {
  create(data: Prisma.AnnouncementUncheckedCreateInput) {
    return prisma.announcement.create({ data, include: withCreator });
  },

  findByIdAndAcademy(id: string, academyId: string) {
    return prisma.announcement.findFirst({ where: { id, academyId }, include: withCreator });
  },

  async findManyByAcademy(academyId: string, { page, limit }: Pagination) {
    const where: Prisma.AnnouncementWhereInput = { academyId };
    const [items, total] = await Promise.all([
      prisma.announcement.findMany({
        where,
        include: withCreator,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.announcement.count({ where }),
    ]);
    return { items, total };
  },

  async findManyForRole(academyId: string, role: UserRole, { page, limit }: Pagination) {
    const where: Prisma.AnnouncementWhereInput = {
      academyId,
      OR: [{ isForAll: true }, { targetRoles: { has: role } }],
    };
    const [items, total] = await Promise.all([
      prisma.announcement.findMany({
        where,
        include: withCreator,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.announcement.count({ where }),
    ]);
    return { items, total };
  },

  update(id: string, data: Prisma.AnnouncementUncheckedUpdateInput) {
    return prisma.announcement.update({ where: { id }, data, include: withCreator });
  },

  delete(id: string) {
    return prisma.announcement.delete({ where: { id } });
  },
};
