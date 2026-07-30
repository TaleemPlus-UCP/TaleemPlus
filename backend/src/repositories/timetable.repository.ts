import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';

const withDetails = {
  offering: {
    select: {
      id: true,
      subject: true,
      sectionId: true,
      section: { select: { id: true, className: true, sectionLabel: true } },
      teacher: { select: { id: true, fullName: true } },
    },
  },
} satisfies Prisma.TimetableSlotInclude;

export const timetableRepository = {
  create(data: Prisma.TimetableSlotUncheckedCreateInput) {
    return prisma.timetableSlot.create({ data, include: withDetails });
  },

  findByIdAndAcademy(id: string, academyId: string) {
    return prisma.timetableSlot.findFirst({ where: { id, academyId }, include: withDetails });
  },

  findManyByAcademy(academyId: string, dayOfWeek?: number) {
    return prisma.timetableSlot.findMany({
      where: { academyId, ...(dayOfWeek ? { dayOfWeek } : {}) },
      include: withDetails,
      orderBy: [{ dayOfWeek: 'asc' }, { startMinutes: 'asc' }],
    });
  },

  findManyByTeacher(academyId: string, teacherId: string, dayOfWeek?: number) {
    return prisma.timetableSlot.findMany({
      where: { academyId, offering: { teacherId }, ...(dayOfWeek ? { dayOfWeek } : {}) },
      include: withDetails,
      orderBy: [{ dayOfWeek: 'asc' }, { startMinutes: 'asc' }],
    });
  },

  findManyBySectionIds(academyId: string, sectionIds: string[], dayOfWeek?: number) {
    return prisma.timetableSlot.findMany({
      where: { academyId, offering: { sectionId: { in: sectionIds } }, ...(dayOfWeek ? { dayOfWeek } : {}) },
      include: withDetails,
      orderBy: [{ dayOfWeek: 'asc' }, { startMinutes: 'asc' }],
    });
  },

  /** Every slot in the academy on a given day — the candidate pool for conflict checks. */
  findManyForDay(academyId: string, dayOfWeek: number, excludeId?: string) {
    return prisma.timetableSlot.findMany({
      where: { academyId, dayOfWeek, ...(excludeId ? { id: { not: excludeId } } : {}) },
      include: withDetails,
    });
  },

  update(id: string, data: Prisma.TimetableSlotUncheckedUpdateInput) {
    return prisma.timetableSlot.update({ where: { id }, data, include: withDetails });
  },

  delete(id: string) {
    return prisma.timetableSlot.delete({ where: { id } });
  },
};
