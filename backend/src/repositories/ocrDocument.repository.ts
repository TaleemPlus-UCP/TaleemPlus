import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';

interface Pagination {
  page: number;
  limit: number;
}

export const ocrDocumentRepository = {
  create(createdById: string, title: string, extractedText: string) {
    return prisma.ocrDocument.create({ data: { createdById, title, extractedText } });
  },

  findByIdAndOwner(id: string, ownerId: string) {
    return prisma.ocrDocument.findFirst({ where: { id, createdById: ownerId } });
  },

  async findManyByOwner(ownerId: string, { page, limit }: Pagination) {
    const where: Prisma.OcrDocumentWhereInput = { createdById: ownerId };
    const [items, total] = await Promise.all([
      prisma.ocrDocument.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.ocrDocument.count({ where }),
    ]);
    return { items, total };
  },

  update(id: string, data: Prisma.OcrDocumentUpdateInput) {
    return prisma.ocrDocument.update({ where: { id }, data });
  },

  delete(id: string) {
    return prisma.ocrDocument.delete({ where: { id } });
  },
};
