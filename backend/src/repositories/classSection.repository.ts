import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';

const withDetails = {
  enrollments: { select: { studentId: true } },
  _count: { select: { enrollments: true, offerings: true } },
} satisfies Prisma.ClassSectionInclude;

export const classSectionRepository = {
  create(data: { academyId: string; className: string; sectionLabel: string }) {
    return prisma.classSection.create({
      data: {
        academy: { connect: { id: data.academyId } },
        className: data.className,
        sectionLabel: data.sectionLabel,
      },
      include: withDetails,
    });
  },

  findManyByAcademy(academyId: string, className?: string) {
    return prisma.classSection.findMany({
      where: { academyId, ...(className ? { className } : {}) },
      include: withDetails,
      orderBy: [{ className: 'asc' }, { sectionLabel: 'asc' }],
    });
  },

  findByIdAndAcademy(id: string, academyId: string) {
    return prisma.classSection.findFirst({ where: { id, academyId }, include: withDetails });
  },

  /** Atomically replaces the full roster — simpler and safer than a diff, and cheap at this scale. */
  async replaceEnrollment(sectionId: string, studentIds: string[]) {
    await prisma.$transaction([
      prisma.sectionEnrollment.deleteMany({ where: { sectionId } }),
      prisma.sectionEnrollment.createMany({
        data: studentIds.map((studentId) => ({ sectionId, studentId })),
      }),
    ]);
    return prisma.classSection.findUniqueOrThrow({ where: { id: sectionId }, include: withDetails });
  },

  delete(id: string) {
    return prisma.classSection.delete({ where: { id } });
  },

  async findEnrolledStudentIds(sectionId: string): Promise<string[]> {
    const rows = await prisma.sectionEnrollment.findMany({ where: { sectionId }, select: { studentId: true } });
    return rows.map((r) => r.studentId);
  },

  async findSectionIdsForStudent(studentId: string): Promise<string[]> {
    const rows = await prisma.sectionEnrollment.findMany({ where: { studentId }, select: { sectionId: true } });
    return rows.map((r) => r.sectionId);
  },
};
