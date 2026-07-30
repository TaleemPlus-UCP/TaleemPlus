import { UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { ForbiddenError, NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { classOfferingRepository } from '../repositories/classOffering.repository';
import { classSectionRepository } from '../repositories/classSection.repository';
import { learningResourceRepository } from '../repositories/learningResource.repository';

interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

/** Mirrors the offering-access boundary used by quizzes/attendance: staff scoped to their own academy (teachers further scoped to offerings they teach), students scoped to offerings whose section they're enrolled in. */
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

async function list(ctx: ActorContext, offeringId: string) {
  await assertCanAccessOffering(ctx, offeringId);
  return learningResourceRepository.findManyByOffering(offeringId);
}

interface CreateInput {
  offeringId: string;
  title: string;
  description?: string;
  linkUrl?: string;
}

async function create(ctx: ActorContext, input: CreateInput) {
  const offering = await assertCanAccessOffering(ctx, input.offeringId);
  if (ctx.role !== 'ADMIN' && ctx.role !== 'TEACHER') {
    throw new ForbiddenError('Only staff can post class resources.');
  }

  const resource = await learningResourceRepository.create({
    academyId: ctx.academyId,
    offeringId: offering.id,
    teacherId: ctx.userId,
    title: input.title,
    description: input.description,
    linkUrl: input.linkUrl,
  });

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.LEARNING_RESOURCE_CREATED,
    metadata: { resourceId: resource.id, offeringId: offering.id },
  });

  return resource;
}

async function remove(ctx: ActorContext, resourceId: string) {
  const resource = await learningResourceRepository.findByIdAndAcademy(resourceId, ctx.academyId);
  if (!resource) throw new NotFoundError('Resource not found in your academy.');

  if (ctx.role !== 'ADMIN' && resource.teacherId !== ctx.userId) {
    throw new ForbiddenError('You can only delete resources you posted.');
  }

  await learningResourceRepository.delete(resourceId);

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.LEARNING_RESOURCE_DELETED,
    metadata: { resourceId },
  });
}

export const learningResourcesService = {
  list,
  create,
  remove,
};
