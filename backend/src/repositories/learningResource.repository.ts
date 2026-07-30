import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';

const withTeacher = {
  teacher: { select: { id: true, fullName: true } },
} satisfies Prisma.LearningResourceInclude;

interface CreateInput {
  academyId: string;
  offeringId: string;
  teacherId: string;
  title: string;
  description?: string;
  linkUrl?: string;
}

export const learningResourceRepository = {
  create(data: CreateInput) {
    return prisma.learningResource.create({ data, include: withTeacher });
  },

  findManyByOffering(offeringId: string) {
    return prisma.learningResource.findMany({
      where: { offeringId },
      include: withTeacher,
      orderBy: { createdAt: 'desc' },
    });
  },

  findByIdAndAcademy(id: string, academyId: string) {
    return prisma.learningResource.findFirst({ where: { id, academyId }, include: withTeacher });
  },

  delete(id: string) {
    return prisma.learningResource.delete({ where: { id } });
  },
};
