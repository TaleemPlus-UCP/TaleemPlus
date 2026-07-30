import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';

const withParticipants = {
  student: { select: { id: true, fullName: true } },
  teacher: { select: { id: true, fullName: true } },
} satisfies Prisma.StudentQueryInclude;

interface CreateInput {
  academyId: string;
  offeringId: string;
  studentId: string;
  teacherId: string;
  question: string;
}

export const studentQueryRepository = {
  create(data: CreateInput) {
    return prisma.studentQuery.create({ data, include: withParticipants });
  },

  findManyByOffering(offeringId: string) {
    return prisma.studentQuery.findMany({
      where: { offeringId },
      include: withParticipants,
      orderBy: { createdAt: 'desc' },
    });
  },

  findByIdAndAcademy(id: string, academyId: string) {
    return prisma.studentQuery.findFirst({ where: { id, academyId }, include: withParticipants });
  },

  answer(id: string, answer: string) {
    return prisma.studentQuery.update({
      where: { id },
      data: { answer, isResolved: true, answeredAt: new Date() },
      include: withParticipants,
    });
  },
};
