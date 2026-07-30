import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';

const withDetails = {
  section: {
    select: {
      id: true,
      className: true,
      sectionLabel: true,
      _count: { select: { enrollments: true } },
    },
  },
  teacher: { select: { id: true, fullName: true, email: true } },
} satisfies Prisma.ClassOfferingInclude;

interface CreateOfferingInput {
  academyId: string;
  sectionId: string;
  teacherId: string;
  subject: string;
}

export const classOfferingRepository = {
  create(data: CreateOfferingInput) {
    return prisma.classOffering.create({
      data: {
        academy: { connect: { id: data.academyId } },
        section: { connect: { id: data.sectionId } },
        teacher: { connect: { id: data.teacherId } },
        subject: data.subject,
      },
      include: withDetails,
    });
  },

  findManyByAcademy(academyId: string, sectionId?: string) {
    return prisma.classOffering.findMany({
      where: { academyId, ...(sectionId ? { sectionId } : {}) },
      include: withDetails,
      orderBy: { createdAt: 'desc' },
    });
  },

  findManyByTeacher(academyId: string, teacherId: string) {
    return prisma.classOffering.findMany({
      where: { academyId, teacherId },
      include: withDetails,
      orderBy: { createdAt: 'desc' },
    });
  },

  findByIdAndAcademy(id: string, academyId: string) {
    return prisma.classOffering.findFirst({ where: { id, academyId }, include: withDetails });
  },

  update(id: string, data: Prisma.ClassOfferingUpdateInput) {
    return prisma.classOffering.update({ where: { id }, data, include: withDetails });
  },

  delete(id: string) {
    return prisma.classOffering.delete({ where: { id } });
  },
};
