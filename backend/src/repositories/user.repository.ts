import { Prisma, UserRole } from '@prisma/client';
import { prisma } from '../config/database';

const withAcademy = { academy: true } satisfies Prisma.UserInclude;

interface PaginationArgs {
  page: number;
  limit: number;
}

interface ListByAcademyAndRoleArgs extends PaginationArgs {
  academyId: string;
  role: UserRole;
  search?: string;
}

interface ListPendingArgs extends PaginationArgs {
  academyId: string;
  role?: UserRole;
}

export const userRepository = {
  create(data: Prisma.UserCreateInput) {
    return prisma.user.create({ data, include: withAcademy });
  },

  findById(id: string) {
    return prisma.user.findFirst({ where: { id, deletedAt: null }, include: withAcademy });
  },

  /** Scoped lookup used by every admin-facing mutation so one academy can never reach another's users. */
  findByIdAndAcademy(id: string, academyId: string) {
    return prisma.user.findFirst({ where: { id, academyId, deletedAt: null }, include: withAcademy });
  },

  findByEmail(email: string) {
    return prisma.user.findFirst({ where: { email: email.toLowerCase(), deletedAt: null }, include: withAcademy });
  },

  async emailExists(email: string): Promise<boolean> {
    const found = await prisma.user.findFirst({
      where: { email: email.toLowerCase(), deletedAt: null },
      select: { id: true },
    });
    return found !== null;
  },

  update(id: string, data: Prisma.UserUpdateInput) {
    return prisma.user.update({ where: { id }, data, include: withAcademy });
  },

  softDelete(id: string) {
    return prisma.user.update({ where: { id }, data: { deletedAt: new Date() } });
  },

  async findPendingByAcademy({ academyId, role, page, limit }: ListPendingArgs) {
    const where: Prisma.UserWhereInput = {
      academyId,
      accountStatus: 'PENDING',
      deletedAt: null,
      ...(role ? { role } : {}),
    };

    const [items, total] = await Promise.all([
      prisma.user.findMany({
        where,
        include: withAcademy,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.user.count({ where }),
    ]);

    return { items, total };
  },

  async findManyByAcademyAndRole({ academyId, role, search, page, limit }: ListByAcademyAndRoleArgs) {
    const where: Prisma.UserWhereInput = {
      academyId,
      role,
      deletedAt: null,
      ...(search
        ? {
            OR: [
              { fullName: { contains: search, mode: 'insensitive' } },
              { email: { contains: search, mode: 'insensitive' } },
              { phoneNumber: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      prisma.user.findMany({
        where,
        include: withAcademy,
        orderBy: { fullName: 'asc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.user.count({ where }),
    ]);

    return { items, total };
  },

  findManyByIds(ids: string[]) {
    return prisma.user.findMany({ where: { id: { in: ids }, deletedAt: null } });
  },

  findApprovedByRole(academyId: string, role: UserRole) {
    return prisma.user.findMany({
      where: { academyId, role, accountStatus: 'ACTIVE', deletedAt: null },
      orderBy: { fullName: 'asc' },
    });
  },
};
