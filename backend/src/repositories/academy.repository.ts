import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';

export const academyRepository = {
  create(data: Prisma.AcademyCreateInput) {
    return prisma.academy.create({ data });
  },

  findById(id: string) {
    return prisma.academy.findUnique({ where: { id } });
  },

  findByCode(code: string) {
    return prisma.academy.findUnique({ where: { code } });
  },

  async codeExists(code: string): Promise<boolean> {
    const found = await prisma.academy.findUnique({ where: { code }, select: { id: true } });
    return found !== null;
  },

  update(id: string, data: Prisma.AcademyUpdateInput) {
    return prisma.academy.update({ where: { id }, data });
  },
};
