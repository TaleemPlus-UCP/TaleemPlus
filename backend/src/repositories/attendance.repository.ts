import { AttendanceStatus } from '@prisma/client';
import { prisma } from '../config/database';

interface UpsertRecordInput {
  academyId: string;
  offeringId: string;
  studentId: string;
  logDate: Date;
  status: AttendanceStatus;
  markedById: string;
}

export const attendanceRepository = {
  /**
   * Upserts a full day's sheet in one transaction, keyed by the
   * (offeringId, studentId, logDate) unique constraint — re-saving the
   * same day overwrites rather than duplicating, mirroring the legacy
   * app's deterministic-document-id upsert behavior.
   */
  async upsertMany(records: UpsertRecordInput[]) {
    await prisma.$transaction(
      records.map((r) =>
        prisma.attendanceRecord.upsert({
          where: {
            offeringId_studentId_logDate: {
              offeringId: r.offeringId,
              studentId: r.studentId,
              logDate: r.logDate,
            },
          },
          create: {
            academyId: r.academyId,
            offeringId: r.offeringId,
            studentId: r.studentId,
            logDate: r.logDate,
            status: r.status,
            markedById: r.markedById,
          },
          update: {
            status: r.status,
            markedById: r.markedById,
          },
        }),
      ),
    );
  },

  findDaySheet(offeringId: string, logDate: Date) {
    return prisma.attendanceRecord.findMany({
      where: { offeringId, logDate },
      include: { student: { select: { id: true, fullName: true } } },
      orderBy: { student: { fullName: 'asc' } },
    });
  },

  findForStudentInRange(studentId: string, academyId: string, start: Date, end: Date) {
    return prisma.attendanceRecord.findMany({
      where: { studentId, academyId, logDate: { gte: start, lt: end } },
      orderBy: { logDate: 'asc' },
    });
  },
};
