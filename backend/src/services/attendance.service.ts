import { AttendanceRecord, UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, ForbiddenError, NotFoundError } from '../exceptions/AppError';
import { attendanceRepository } from '../repositories/attendance.repository';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { classOfferingRepository } from '../repositories/classOffering.repository';
import { classSectionRepository } from '../repositories/classSection.repository';
import { parentChildLinkRepository } from '../repositories/parentChildLink.repository';
import { userRepository } from '../repositories/user.repository';

interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

interface MarkRecordInput {
  studentId: string;
  status: 'PRESENT' | 'ABSENT' | 'LATE';
}

async function markSheet(ctx: ActorContext, offeringId: string, logDate: Date, records: MarkRecordInput[]) {
  const offering = await classOfferingRepository.findByIdAndAcademy(offeringId, ctx.academyId);
  if (!offering) throw new NotFoundError('Class not found in your academy.');

  const enrolledIds = new Set(await classSectionRepository.findEnrolledStudentIds(offering.sectionId));
  const invalidIds = records.map((r) => r.studentId).filter((id) => !enrolledIds.has(id));
  if (invalidIds.length > 0) {
    throw new BadRequestError('Some students are not enrolled in this class section.', {
      invalidStudentIds: invalidIds,
    });
  }

  await attendanceRepository.upsertMany(
    records.map((r) => ({
      academyId: ctx.academyId,
      offeringId,
      studentId: r.studentId,
      logDate,
      status: r.status,
      markedById: ctx.userId,
    })),
  );

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.ATTENDANCE_MARKED,
    metadata: { offeringId, logDate: logDate.toISOString(), count: records.length },
  });

  return getDaySheet(ctx, offeringId, logDate);
}

async function getDaySheet(ctx: ActorContext, offeringId: string, logDate: Date) {
  const offering = await classOfferingRepository.findByIdAndAcademy(offeringId, ctx.academyId);
  if (!offering) throw new NotFoundError('Class not found in your academy.');

  const enrolledIds = await classSectionRepository.findEnrolledStudentIds(offering.sectionId);
  const students = await userRepository.findManyByIds(enrolledIds);
  const existing = await attendanceRepository.findDaySheet(offeringId, logDate);
  const existingByStudent = new Map(existing.map((r) => [r.studentId, r]));

  const sheet = students
    .map((student) => {
      const record = existingByStudent.get(student.id);
      return {
        studentId: student.id,
        fullName: student.fullName,
        status: record?.status ?? ('ABSENT' as const),
        recordedAt: record?.recordedAt ?? null,
      };
    })
    .sort((a, b) => a.fullName.localeCompare(b.fullName));

  return { offeringId, logDate, students: sheet };
}

/**
 * Mirrors the tenant/role boundaries used everywhere else: staff can view
 * any student in their own academy, a student can only view themselves,
 * and a parent can only view a linked child.
 */
async function assertCanViewStudent(ctx: ActorContext, studentId: string) {
  const student = await userRepository.findById(studentId);
  if (!student || student.role !== 'STUDENT' || !student.academyId) {
    throw new NotFoundError('Student not found.');
  }

  if (ctx.role === 'ADMIN' || ctx.role === 'TEACHER') {
    if (student.academyId !== ctx.academyId) {
      throw new NotFoundError('Student not found in your academy.');
    }
    return student;
  }

  if (ctx.role === 'STUDENT') {
    if (ctx.userId !== studentId) {
      throw new ForbiddenError('You can only view your own attendance.');
    }
    return student;
  }

  if (ctx.role === 'PARENT') {
    const linked = await parentChildLinkRepository.existsLink(ctx.userId, studentId);
    if (!linked) {
      throw new ForbiddenError('You can only view attendance for your linked children.');
    }
    return student;
  }

  throw new ForbiddenError('You do not have access to this attendance record.');
}

function summarize(records: AttendanceRecord[]) {
  const totalDays = records.length;
  const presentCount = records.filter((r) => r.status === 'PRESENT').length;
  const absentCount = records.filter((r) => r.status === 'ABSENT').length;
  const lateCount = records.filter((r) => r.status === 'LATE').length;
  const percentage = totalDays === 0 ? 0 : Math.round(((presentCount + lateCount) / totalDays) * 1000) / 10;
  return { totalDays, presentCount, absentCount, lateCount, percentage };
}

function monthRange(year: number, month: number) {
  // UTC to match the `@db.Date` column, which carries no timezone.
  const start = new Date(Date.UTC(year, month - 1, 1));
  const end = new Date(Date.UTC(year, month, 1));
  return { start, end };
}

async function getStudentMonthly(ctx: ActorContext, studentId: string, year?: number, month?: number) {
  const student = await assertCanViewStudent(ctx, studentId);
  const now = new Date();
  const resolvedYear = year ?? now.getUTCFullYear();
  const resolvedMonth = month ?? now.getUTCMonth() + 1;

  const { start, end } = monthRange(resolvedYear, resolvedMonth);
  const records = await attendanceRepository.findForStudentInRange(studentId, student.academyId!, start, end);

  return {
    year: resolvedYear,
    month: resolvedMonth,
    records: records.map((r) => ({ logDate: r.logDate, status: r.status, recordedAt: r.recordedAt })),
    summary: summarize(records),
  };
}

async function getStudentYearly(ctx: ActorContext, studentId: string, year?: number) {
  const student = await assertCanViewStudent(ctx, studentId);
  const resolvedYear = year ?? new Date().getUTCFullYear();

  const start = new Date(Date.UTC(resolvedYear, 0, 1));
  const end = new Date(Date.UTC(resolvedYear + 1, 0, 1));
  const records = await attendanceRepository.findForStudentInRange(studentId, student.academyId!, start, end);

  const months = Array.from({ length: 12 }, (_, i) => {
    const monthNumber = i + 1;
    const monthRecords = records.filter((r) => r.logDate.getUTCMonth() + 1 === monthNumber);
    return { month: monthNumber, ...summarize(monthRecords) };
  });

  return { year: resolvedYear, months };
}

export const attendanceService = {
  markSheet,
  getDaySheet,
  getStudentMonthly,
  getStudentYearly,
};
