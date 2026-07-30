import { UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { classOfferingRepository } from '../repositories/classOffering.repository';
import { quizRepository } from '../repositories/quiz.repository';
import { buildPaginationMeta } from '../utils/apiResponse';
import { computeGradeSuggestion } from '../utils/grading';

/**
 * Quiz definitions carry the answer key (MCQ `correctIndex`, `gradingKeywords`
 * for the AI Smart Grader) — only staff ever read or write a `Quiz` directly.
 * Students/parents get their results through the Marks endpoints instead,
 * which only ever expose marksObtained/percentage/gradeLetter, never the
 * underlying questions. (The legacy app's own student-facing "take quiz"
 * screen was a static "take this on paper" notice, not an in-app quiz
 * reader — see phases.md — so this isn't a regression, just made explicit.)
 */
interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

interface Pagination {
  page: number;
  limit: number;
}

interface QuestionInput {
  text: string;
  type: 'MCQ' | 'SHORT' | 'LONG';
  options?: string[];
  correctIndex?: number;
  marks: number;
  gradingKeywords: string[];
}

interface CreateQuizInput {
  offeringId: string;
  title: string;
  subject: string;
  session?: string;
  chapter?: string;
  difficulty: 'EASY' | 'MEDIUM' | 'HARD';
  totalMarks: number;
  testDate: Date;
  instructions?: string;
  questions: QuestionInput[];
}

async function assertOfferingInAcademy(academyId: string, offeringId: string) {
  const offering = await classOfferingRepository.findByIdAndAcademy(offeringId, academyId);
  if (!offering) throw new BadRequestError('offeringId does not belong to your academy.');
  return offering;
}

async function create(ctx: ActorContext, input: CreateQuizInput) {
  await assertOfferingInAcademy(ctx.academyId, input.offeringId);

  const quiz = await quizRepository.create({
    academyId: ctx.academyId,
    offeringId: input.offeringId,
    title: input.title,
    subject: input.subject,
    session: input.session,
    chapter: input.chapter,
    difficulty: input.difficulty,
    totalMarks: input.totalMarks,
    testDate: input.testDate,
    instructions: input.instructions,
    createdById: ctx.userId,
    questions: input.questions,
  });

  await auditLogRepository.record({ userId: ctx.userId, action: AUDIT_ACTIONS.QUIZ_CREATED, metadata: { quizId: quiz.id } });

  return quiz;
}

interface ListFilters {
  offeringId?: string;
}

async function list(ctx: ActorContext, filters: ListFilters, pagination: Pagination) {
  if (ctx.role === 'ADMIN') {
    const { items, total } = await quizRepository.findManyByAcademy(ctx.academyId, filters.offeringId, pagination);
    return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
  }

  // TEACHER — only quizzes for offerings they personally teach.
  const offerings = await classOfferingRepository.findManyByTeacher(ctx.academyId, ctx.userId);
  const offeringIds = filters.offeringId ? [filters.offeringId] : offerings.map((o) => o.id);
  if (offeringIds.length === 0) return { items: [], meta: buildPaginationMeta(pagination.page, pagination.limit, 0) };
  const { items, total } = await quizRepository.findManyByOfferingIds(ctx.academyId, offeringIds, pagination);
  return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
}

async function assertCanAccessQuiz(ctx: ActorContext, quiz: { offeringId: string }) {
  if (ctx.role === 'ADMIN') return;

  const offering = await classOfferingRepository.findByIdAndAcademy(quiz.offeringId, ctx.academyId);
  if (!offering || offering.teacherId !== ctx.userId) {
    throw new NotFoundError('Quiz not found in your academy.');
  }
}

async function getOne(ctx: ActorContext, quizId: string) {
  const quiz = await quizRepository.findByIdAndAcademy(quizId, ctx.academyId);
  if (!quiz) throw new NotFoundError('Quiz not found in your academy.');
  await assertCanAccessQuiz(ctx, quiz);
  return quiz;
}

interface UpdateQuizInput {
  title?: string;
  subject?: string;
  session?: string | null;
  chapter?: string | null;
  difficulty?: 'EASY' | 'MEDIUM' | 'HARD';
  totalMarks?: number;
  testDate?: Date;
  instructions?: string | null;
  questions?: QuestionInput[];
}

async function update(ctx: ActorContext, quizId: string, input: UpdateQuizInput) {
  const quiz = await quizRepository.findByIdAndAcademy(quizId, ctx.academyId);
  if (!quiz) throw new NotFoundError('Quiz not found in your academy.');

  const { questions, ...meta } = input;

  let updated = await quizRepository.update(quizId, meta);
  if (questions) {
    updated = await quizRepository.replaceQuestions(quizId, questions);
  }

  await auditLogRepository.record({ userId: ctx.userId, action: AUDIT_ACTIONS.QUIZ_UPDATED, metadata: { quizId } });

  return updated;
}

async function remove(ctx: ActorContext, quizId: string) {
  const quiz = await quizRepository.findByIdAndAcademy(quizId, ctx.academyId);
  if (!quiz) throw new NotFoundError('Quiz not found in your academy.');

  await quizRepository.delete(quizId);

  await auditLogRepository.record({ userId: ctx.userId, action: AUDIT_ACTIONS.QUIZ_DELETED, metadata: { quizId } });
}

async function gradeSuggestion(ctx: ActorContext, quizId: string, questionId: string, ocrText: string) {
  const quiz = await quizRepository.findByIdAndAcademy(quizId, ctx.academyId);
  if (!quiz) throw new NotFoundError('Quiz not found in your academy.');
  await assertCanAccessQuiz(ctx, quiz);

  const question = await quizRepository.findQuestionById(quizId, questionId);
  if (!question) throw new NotFoundError('Question not found on this quiz.');
  if (question.type === 'MCQ') {
    throw new BadRequestError('The AI Smart Grader only applies to Short/Long answer questions, not MCQs.');
  }

  return computeGradeSuggestion(ocrText, question.gradingKeywords, question.marks.toNumber());
}

export const quizzesService = {
  create,
  list,
  getOne,
  update,
  remove,
  gradeSuggestion,
};
