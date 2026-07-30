import { UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { classOfferingRepository } from '../repositories/classOffering.repository';
import { classSectionRepository } from '../repositories/classSection.repository';
import { userRepository } from '../repositories/user.repository';

interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

async function assertTeacherEligible(academyId: string, teacherId: string): Promise<void> {
  const teacher = await userRepository.findById(teacherId);
  if (!teacher || teacher.academyId !== academyId || teacher.role !== 'TEACHER' || teacher.accountStatus !== 'ACTIVE') {
    throw new BadRequestError('teacherId must be an ACTIVE teacher in your academy.');
  }
}

async function list(ctx: ActorContext, sectionId?: string) {
  if (ctx.role === 'TEACHER') {
    const offerings = await classOfferingRepository.findManyByTeacher(ctx.academyId, ctx.userId);
    return sectionId ? offerings.filter((o) => o.sectionId === sectionId) : offerings;
  }
  return classOfferingRepository.findManyByAcademy(ctx.academyId, sectionId);
}

interface CreateOfferingInput {
  sectionId: string;
  teacherId: string;
  subject: string;
}

async function create(ctx: ActorContext, input: CreateOfferingInput) {
  const section = await classSectionRepository.findByIdAndAcademy(input.sectionId, ctx.academyId);
  if (!section) throw new NotFoundError('Class section not found in your academy.');

  await assertTeacherEligible(ctx.academyId, input.teacherId);

  const offering = await classOfferingRepository.create({
    academyId: ctx.academyId,
    sectionId: input.sectionId,
    teacherId: input.teacherId,
    subject: input.subject,
  });

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.CLASS_OFFERING_CREATED,
    metadata: { offeringId: offering.id, sectionId: input.sectionId },
  });

  return offering;
}

async function getOne(ctx: ActorContext, offeringId: string) {
  const offering = await classOfferingRepository.findByIdAndAcademy(offeringId, ctx.academyId);
  if (!offering) throw new NotFoundError('Class not found in your academy.');
  return offering;
}

interface UpdateOfferingInput {
  subject?: string;
  teacherId?: string;
}

async function update(ctx: ActorContext, offeringId: string, input: UpdateOfferingInput) {
  const offering = await classOfferingRepository.findByIdAndAcademy(offeringId, ctx.academyId);
  if (!offering) throw new NotFoundError('Class not found in your academy.');

  if (input.teacherId) {
    await assertTeacherEligible(ctx.academyId, input.teacherId);
  }

  const updated = await classOfferingRepository.update(offeringId, {
    ...(input.subject !== undefined ? { subject: input.subject } : {}),
    ...(input.teacherId ? { teacher: { connect: { id: input.teacherId } } } : {}),
  });

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.CLASS_OFFERING_UPDATED,
    metadata: { offeringId },
  });

  return updated;
}

async function remove(ctx: ActorContext, offeringId: string) {
  const offering = await classOfferingRepository.findByIdAndAcademy(offeringId, ctx.academyId);
  if (!offering) throw new NotFoundError('Class not found in your academy.');

  await classOfferingRepository.delete(offeringId);

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.CLASS_OFFERING_DELETED,
    metadata: { offeringId },
  });
}

export const classOfferingsService = {
  list,
  create,
  getOne,
  update,
  remove,
};
