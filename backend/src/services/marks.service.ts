import { UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, ForbiddenError, NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { classOfferingRepository } from '../repositories/classOffering.repository';
import { classSectionRepository } from '../repositories/classSection.repository';
import { parentChildLinkRepository } from '../repositories/parentChildLink.repository';
import { quizRepository } from '../repositories/quiz.repository';
import { testMarkRepository } from '../repositories/testMark.repository';
import { userRepository } from '../repositories/user.repository';
import { buildPaginationMeta } from '../utils/apiResponse';
import { calculateGradeLetter, calculatePercentage } from '../utils/grading';

interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

interface Pagination {
  page: number;
  limit: number;
}

interface MarkRecordInput {
  studentId: string;
  marksObtained: number;
  teacherFeedback?: string;
}

async function assertStaffCanAccessQuiz(ctx: ActorContext, quizId: string) {
  const quiz = await quizRepository.findByIdAndAcademy(quizId, ctx.academyId);
  if (!quiz) throw new NotFoundError('Quiz not found in your academy.');

  if (ctx.role === 'TEACHER') {
    const offering = await classOfferingRepository.findByIdAndAcademy(quiz.offeringId, ctx.academyId);
    if (!offering || offering.teacherId !== ctx.userId) {
      throw new NotFoundError('Quiz not found in your academy.');
    }
  }

  return quiz;
}

async function upsertMarks(ctx: ActorContext, quizId: string, records: MarkRecordInput[]) {
  const quiz = await assertStaffCanAccessQuiz(ctx, quizId);
  const offering = await classOfferingRepository.findByIdAndAcademy(quiz.offeringId, ctx.academyId);
  if (!offering) throw new NotFoundError('Class offering for this quiz no longer exists.');

  const enrolledIds = new Set(await classSectionRepository.findEnrolledStudentIds(offering.sectionId));
  const invalidIds = records.map((r) => r.studentId).filter((id) => !enrolledIds.has(id));
  if (invalidIds.length > 0) {
    throw new BadRequestError('Some students are not enrolled in this class section.', { invalidStudentIds: invalidIds });
  }

  const totalMarks = quiz.totalMarks.toNumber();

  await testMarkRepository.upsertMany(
    records.map((r) => {
      const percentage = calculatePercentage(r.marksObtained, totalMarks);
      return {
        academyId: ctx.academyId,
        quizId,
        studentId: r.studentId,
        marksObtained: r.marksObtained,
        totalMarks,
        percentage,
        gradeLetter: calculateGradeLetter(percentage),
        teacherFeedback: r.teacherFeedback,
      };
    }),
  );

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.MARKS_UPSERTED,
    metadata: { quizId, count: records.length },
  });

  return testMarkRepository.findManyByQuiz(quizId);
}

async function listForQuiz(ctx: ActorContext, quizId: string) {
  await assertStaffCanAccessQuiz(ctx, quizId);
  return testMarkRepository.findManyByQuiz(quizId);
}

interface StudentMarksFilters {
  subject?: string;
  year?: number;
  month?: number;
}

async function assertCanViewStudent(ctx: ActorContext, studentId: string) {
  const student = await userRepository.findById(studentId);
  if (!student || student.role !== 'STUDENT' || !student.academyId) {
    throw new NotFoundError('Student not found.');
  }

  if (ctx.role === 'ADMIN' || ctx.role === 'TEACHER') {
    if (student.academyId !== ctx.academyId) throw new NotFoundError('Student not found in your academy.');
    return student;
  }

  if (ctx.role === 'STUDENT') {
    if (ctx.userId !== studentId) throw new ForbiddenError('You can only view your own marks.');
    return student;
  }

  // PARENT
  const linked = await parentChildLinkRepository.existsLink(ctx.userId, studentId);
  if (!linked) throw new ForbiddenError('You can only view marks for your linked children.');
  return student;
}

async function listForStudent(ctx: ActorContext, studentId: string, filters: StudentMarksFilters, pagination: Pagination) {
  await assertCanViewStudent(ctx, studentId);
  const { items, total } = await testMarkRepository.findManyForStudent(studentId, filters, pagination);
  return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
}

async function deleteMark(ctx: ActorContext, markId: string) {
  const mark = await testMarkRepository.findByIdAndAcademy(markId, ctx.academyId);
  if (!mark) throw new NotFoundError('Mark not found.');

  await testMarkRepository.delete(markId);

  await auditLogRepository.record({ userId: ctx.userId, action: AUDIT_ACTIONS.MARK_DELETED, metadata: { markId } });
}

export const marksService = {
  upsertMarks,
  listForQuiz,
  listForStudent,
  deleteMark,
};
