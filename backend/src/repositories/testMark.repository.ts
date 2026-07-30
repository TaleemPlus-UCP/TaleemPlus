import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';

const withQuizAndStudent = {
  student: { select: { id: true, fullName: true } },
  quiz: { select: { id: true, title: true, subject: true, testDate: true, offeringId: true } },
} satisfies Prisma.TestMarkInclude;

interface UpsertMarkInput {
  academyId: string;
  quizId: string;
  studentId: string;
  marksObtained: number;
  totalMarks: number;
  percentage: number;
  gradeLetter: string;
  teacherFeedback?: string;
}

interface Pagination {
  page: number;
  limit: number;
}

interface StudentMarksFilters {
  subject?: string;
  year?: number;
  month?: number;
}

export const testMarkRepository = {
  async upsertMany(records: UpsertMarkInput[]) {
    await prisma.$transaction(
      records.map((r) =>
        prisma.testMark.upsert({
          where: { quizId_studentId: { quizId: r.quizId, studentId: r.studentId } },
          create: {
            academyId: r.academyId,
            quizId: r.quizId,
            studentId: r.studentId,
            marksObtained: r.marksObtained,
            totalMarks: r.totalMarks,
            percentage: r.percentage,
            gradeLetter: r.gradeLetter,
            teacherFeedback: r.teacherFeedback,
          },
          update: {
            marksObtained: r.marksObtained,
            totalMarks: r.totalMarks,
            percentage: r.percentage,
            gradeLetter: r.gradeLetter,
            teacherFeedback: r.teacherFeedback,
          },
        }),
      ),
    );
  },

  findManyByQuiz(quizId: string) {
    return prisma.testMark.findMany({
      where: { quizId },
      include: withQuizAndStudent,
      orderBy: { student: { fullName: 'asc' } },
    });
  },

  findByIdAndAcademy(id: string, academyId: string) {
    return prisma.testMark.findFirst({ where: { id, academyId }, include: withQuizAndStudent });
  },

  async findManyForStudent(studentId: string, filters: StudentMarksFilters, { page, limit }: Pagination) {
    let testDateFilter: Prisma.DateTimeFilter | undefined;
    if (filters.month) {
      // A specific month always needs a year to anchor an exact range —
      // default to the current one, same convention as the Attendance module.
      const year = filters.year ?? new Date().getUTCFullYear();
      testDateFilter = { gte: new Date(Date.UTC(year, filters.month - 1, 1)), lt: new Date(Date.UTC(year, filters.month, 1)) };
    } else if (filters.year) {
      testDateFilter = { gte: new Date(Date.UTC(filters.year, 0, 1)), lt: new Date(Date.UTC(filters.year + 1, 0, 1)) };
    }

    const where: Prisma.TestMarkWhereInput = {
      studentId,
      quiz: {
        ...(filters.subject ? { subject: { equals: filters.subject, mode: 'insensitive' } } : {}),
        ...(testDateFilter ? { testDate: testDateFilter } : {}),
      },
    };

    const [items, total] = await Promise.all([
      prisma.testMark.findMany({
        where,
        include: withQuizAndStudent,
        orderBy: { quiz: { testDate: 'desc' } },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.testMark.count({ where }),
    ]);

    return { items, total };
  },

  findAllForAcademyWithQuiz(academyId: string) {
    return prisma.testMark.findMany({
      where: { academyId },
      include: withQuizAndStudent,
    });
  },

  delete(id: string) {
    return prisma.testMark.delete({ where: { id } });
  },
};
