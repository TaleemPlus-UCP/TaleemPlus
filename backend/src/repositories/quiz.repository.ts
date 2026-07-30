import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';

const withDetails = {
  offering: {
    select: {
      id: true,
      subject: true,
      sectionId: true,
      teacherId: true,
      section: { select: { id: true, className: true, sectionLabel: true } },
      teacher: { select: { id: true, fullName: true } },
    },
  },
  questions: { orderBy: { order: 'asc' } },
  createdBy: { select: { id: true, fullName: true } },
} satisfies Prisma.QuizInclude;

interface QuestionInput {
  text: string;
  type: 'MCQ' | 'SHORT' | 'LONG';
  options?: string[];
  correctIndex?: number;
  marks: number;
  gradingKeywords: string[];
}

interface CreateQuizInput {
  academyId: string;
  offeringId: string;
  title: string;
  subject: string;
  session?: string;
  chapter?: string;
  difficulty: 'EASY' | 'MEDIUM' | 'HARD';
  totalMarks: number;
  testDate: Date;
  instructions?: string;
  createdById: string;
  questions: QuestionInput[];
}

interface Pagination {
  page: number;
  limit: number;
}

export const quizRepository = {
  create(input: CreateQuizInput) {
    return prisma.quiz.create({
      data: {
        academyId: input.academyId,
        offeringId: input.offeringId,
        title: input.title,
        subject: input.subject,
        session: input.session,
        chapter: input.chapter,
        difficulty: input.difficulty,
        totalMarks: input.totalMarks,
        testDate: input.testDate,
        instructions: input.instructions,
        createdById: input.createdById,
        questions: {
          create: input.questions.map((q, index) => ({
            order: index,
            text: q.text,
            type: q.type,
            options: q.options ?? [],
            correctIndex: q.correctIndex,
            marks: q.marks,
            gradingKeywords: q.gradingKeywords,
          })),
        },
      },
      include: withDetails,
    });
  },

  findByIdAndAcademy(id: string, academyId: string) {
    return prisma.quiz.findFirst({ where: { id, academyId }, include: withDetails });
  },

  async findManyByAcademy(academyId: string, offeringId: string | undefined, { page, limit }: Pagination) {
    const where: Prisma.QuizWhereInput = { academyId, ...(offeringId ? { offeringId } : {}) };
    const [items, total] = await Promise.all([
      prisma.quiz.findMany({
        where,
        include: withDetails,
        orderBy: { testDate: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.quiz.count({ where }),
    ]);
    return { items, total };
  },

  async findManyByOfferingIds(academyId: string, offeringIds: string[], { page, limit }: Pagination) {
    const where: Prisma.QuizWhereInput = { academyId, offeringId: { in: offeringIds } };
    const [items, total] = await Promise.all([
      prisma.quiz.findMany({
        where,
        include: withDetails,
        orderBy: { testDate: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.quiz.count({ where }),
    ]);
    return { items, total };
  },

  findQuestionById(quizId: string, questionId: string) {
    return prisma.quizQuestion.findFirst({ where: { id: questionId, quizId } });
  },

  update(id: string, data: Prisma.QuizUpdateInput) {
    return prisma.quiz.update({ where: { id }, data, include: withDetails });
  },

  async replaceQuestions(quizId: string, questions: QuestionInput[]) {
    await prisma.$transaction([
      prisma.quizQuestion.deleteMany({ where: { quizId } }),
      prisma.quizQuestion.createMany({
        data: questions.map((q, index) => ({
          quizId,
          order: index,
          text: q.text,
          type: q.type,
          options: q.options ?? [],
          correctIndex: q.correctIndex,
          marks: q.marks,
          gradingKeywords: q.gradingKeywords,
        })),
      }),
    ]);
    return prisma.quiz.findUniqueOrThrow({ where: { id: quizId }, include: withDetails });
  },

  delete(id: string) {
    return prisma.quiz.delete({ where: { id } });
  },
};
