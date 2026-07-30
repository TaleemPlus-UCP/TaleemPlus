import { UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, ForbiddenError, NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { classOfferingRepository } from '../repositories/classOffering.repository';
import { classSectionRepository } from '../repositories/classSection.repository';
import { studentQueryRepository } from '../repositories/studentQuery.repository';

interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

/** Same offering-access boundary as Learning Resources — see that service for the rationale. */
async function assertCanAccessOffering(ctx: ActorContext, offeringId: string) {
  const offering = await classOfferingRepository.findByIdAndAcademy(offeringId, ctx.academyId);
  if (!offering) throw new NotFoundError('Class not found in your academy.');

  if (ctx.role === 'ADMIN') return offering;

  if (ctx.role === 'TEACHER') {
    if (offering.teacherId !== ctx.userId) {
      throw new ForbiddenError('You can only access classes you teach.');
    }
    return offering;
  }

  if (ctx.role === 'STUDENT') {
    const enrolledIds = await classSectionRepository.findEnrolledStudentIds(offering.sectionId);
    if (!enrolledIds.includes(ctx.userId)) {
      throw new ForbiddenError('You are not enrolled in this class.');
    }
    return offering;
  }

  throw new ForbiddenError('You do not have access to this class.');
}

/** Every query and answer for the offering — a shared class-discussion wall, not scoped to the asker. */
async function list(ctx: ActorContext, offeringId: string) {
  await assertCanAccessOffering(ctx, offeringId);
  return studentQueryRepository.findManyByOffering(offeringId);
}

interface CreateInput {
  offeringId: string;
  question: string;
}

async function create(ctx: ActorContext, input: CreateInput) {
  if (ctx.role !== 'STUDENT') {
    throw new ForbiddenError('Only students can post a question.');
  }
  const offering = await assertCanAccessOffering(ctx, input.offeringId);
  if (!offering.teacherId) {
    throw new BadRequestError('This class has no assigned teacher yet.');
  }

  const query = await studentQueryRepository.create({
    academyId: ctx.academyId,
    offeringId: offering.id,
    studentId: ctx.userId,
    teacherId: offering.teacherId,
    question: input.question,
  });

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.STUDENT_QUERY_CREATED,
    metadata: { queryId: query.id, offeringId: offering.id },
  });

  return query;
}

async function answer(ctx: ActorContext, queryId: string, answerText: string) {
  const query = await studentQueryRepository.findByIdAndAcademy(queryId, ctx.academyId);
  if (!query) throw new NotFoundError('Question not found in your academy.');

  if (ctx.role !== 'ADMIN' && query.teacherId !== ctx.userId) {
    throw new ForbiddenError('You can only answer questions for classes you teach.');
  }

  const updated = await studentQueryRepository.answer(queryId, answerText);

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.STUDENT_QUERY_ANSWERED,
    metadata: { queryId },
  });

  return updated;
}

export const studentQueriesService = {
  list,
  create,
  answer,
};
