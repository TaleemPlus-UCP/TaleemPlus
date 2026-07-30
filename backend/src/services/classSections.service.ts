import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { classSectionRepository } from '../repositories/classSection.repository';
import { userRepository } from '../repositories/user.repository';

interface ActorContext {
  adminId: string;
  academyId: string;
}

async function list(ctx: ActorContext, className?: string) {
  return classSectionRepository.findManyByAcademy(ctx.academyId, className);
}

async function create(ctx: ActorContext, input: { className: string; sectionLabel: string }) {
  const section = await classSectionRepository.create({
    academyId: ctx.academyId,
    className: input.className,
    sectionLabel: input.sectionLabel,
  });

  await auditLogRepository.record({
    userId: ctx.adminId,
    action: AUDIT_ACTIONS.SECTION_CREATED,
    metadata: { sectionId: section.id },
  });

  return section;
}

/**
 * Validates every id refers to an ACTIVE STUDENT in this academy before
 * writing anything — the enrollment roster must never silently include a
 * student from another academy, a non-student, or an unapproved account.
 */
async function validateStudentIds(academyId: string, studentIds: string[]): Promise<string[]> {
  const uniqueIds = Array.from(new Set(studentIds));
  if (uniqueIds.length === 0) return uniqueIds;

  const users = await userRepository.findManyByIds(uniqueIds);
  const usersById = new Map(users.map((u) => [u.id, u]));

  const invalid = uniqueIds.filter((id) => {
    const user = usersById.get(id);
    return !user || user.role !== 'STUDENT' || user.academyId !== academyId || user.accountStatus !== 'ACTIVE';
  });

  if (invalid.length > 0) {
    throw new BadRequestError('Some student ids are invalid, not students, not ACTIVE, or outside your academy.', {
      invalidStudentIds: invalid,
    });
  }

  return uniqueIds;
}

async function updateEnrollment(ctx: ActorContext, sectionId: string, studentIds: string[]) {
  const section = await classSectionRepository.findByIdAndAcademy(sectionId, ctx.academyId);
  if (!section) throw new NotFoundError('Class section not found in your academy.');

  const validatedIds = await validateStudentIds(ctx.academyId, studentIds);
  const updated = await classSectionRepository.replaceEnrollment(sectionId, validatedIds);

  await auditLogRepository.record({
    userId: ctx.adminId,
    action: AUDIT_ACTIONS.SECTION_ENROLLMENT_UPDATED,
    metadata: { sectionId, enrolledCount: validatedIds.length },
  });

  return updated;
}

async function remove(ctx: ActorContext, sectionId: string) {
  const section = await classSectionRepository.findByIdAndAcademy(sectionId, ctx.academyId);
  if (!section) throw new NotFoundError('Class section not found in your academy.');

  await classSectionRepository.delete(sectionId);

  await auditLogRepository.record({
    userId: ctx.adminId,
    action: AUDIT_ACTIONS.SECTION_DELETED,
    metadata: { sectionId },
  });
}

export const classSectionsService = {
  list,
  create,
  updateEnrollment,
  remove,
};
