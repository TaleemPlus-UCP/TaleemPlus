import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';

const withChildAcademy = {
  child: { include: { academy: true } },
} satisfies Prisma.ParentChildLinkInclude;

export const parentChildLinkRepository = {
  async existsLink(parentId: string, childId: string): Promise<boolean> {
    const found = await prisma.parentChildLink.findUnique({
      where: { parentId_childId: { parentId, childId } },
      select: { id: true },
    });
    return found !== null;
  },

  create(parentId: string, childId: string) {
    return prisma.parentChildLink.create({ data: { parentId, childId } });
  },

  delete(parentId: string, childId: string) {
    return prisma.parentChildLink.delete({ where: { parentId_childId: { parentId, childId } } });
  },

  async findChildrenForParent(parentId: string) {
    const links = await prisma.parentChildLink.findMany({
      where: { parentId },
      include: withChildAcademy,
      orderBy: { createdAt: 'desc' },
    });
    return links.map((link) => link.child);
  },
};
