import { UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, ConflictError, ForbiddenError, NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { classOfferingRepository } from '../repositories/classOffering.repository';
import { classSectionRepository } from '../repositories/classSection.repository';
import { parentChildLinkRepository } from '../repositories/parentChildLink.repository';
import { timetableRepository } from '../repositories/timetable.repository';
import { userRepository } from '../repositories/user.repository';

interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

interface SlotFields {
  isBreak: boolean;
  offeringId?: string | null;
  dayOfWeek: number;
  startMinutes: number;
  endMinutes: number;
  room?: string | null;
  semester?: string | null;
  effectiveFrom: Date;
  effectiveTo?: Date | null;
}

function dateRangesOverlap(aFrom: Date, aTo: Date | null, bFrom: Date, bTo: Date | null): boolean {
  const aEnd = aTo ?? new Date('9999-12-31');
  const bEnd = bTo ?? new Date('9999-12-31');
  return aFrom <= bEnd && bFrom <= aEnd;
}

/**
 * Server-side equivalent of the legacy app's client-only pre-save check:
 * rejects a slot that would double-book a teacher, a room, or a section,
 * considering day-of-week, time overlap, and effective-date-range overlap
 * together (a slot only conflicts with another if all three overlap).
 */
async function assertNoConflict(
  ctx: ActorContext,
  candidate: SlotFields & { teacherId: string | null; sectionId: string | null },
  excludeId?: string,
) {
  const daySlots = await timetableRepository.findManyForDay(ctx.academyId, candidate.dayOfWeek, excludeId);

  for (const existing of daySlots) {
    const timeOverlap = candidate.startMinutes < existing.endMinutes && candidate.endMinutes > existing.startMinutes;
    if (!timeOverlap) continue;

    const dateOverlap = dateRangesOverlap(
      candidate.effectiveFrom,
      candidate.effectiveTo ?? null,
      existing.effectiveFrom,
      existing.effectiveTo,
    );
    if (!dateOverlap) continue;

    const existingTeacherId = existing.offering?.teacher?.id ?? null;
    if (candidate.teacherId && existingTeacherId && candidate.teacherId === existingTeacherId) {
      throw new ConflictError(
        `Teacher ${existing.offering?.teacher?.fullName ?? 'this teacher'} is already scheduled at this time.`,
      );
    }

    if (candidate.room && existing.room && candidate.room.trim().toLowerCase() === existing.room.trim().toLowerCase()) {
      throw new ConflictError(`Room ${existing.room} is already booked at this time.`);
    }

    const existingSectionId = existing.offering?.sectionId ?? null;
    if (!existing.isBreak && candidate.sectionId && existingSectionId && candidate.sectionId === existingSectionId) {
      const label = existing.offering
        ? `${existing.offering.section.className}-${existing.offering.section.sectionLabel}`
        : 'This section';
      throw new ConflictError(`${label} already has a session at this time.`);
    }
  }
}

async function resolveOfferingContext(academyId: string, offeringId: string | null | undefined) {
  if (!offeringId) return { teacherId: null, sectionId: null };
  const offering = await classOfferingRepository.findByIdAndAcademy(offeringId, academyId);
  if (!offering) throw new BadRequestError('offeringId does not belong to your academy.');
  return { teacherId: offering.teacherId, sectionId: offering.sectionId };
}

async function create(ctx: ActorContext, input: SlotFields) {
  const { teacherId, sectionId } = await resolveOfferingContext(ctx.academyId, input.offeringId);

  await assertNoConflict(ctx, { ...input, teacherId, sectionId });

  const slot = await timetableRepository.create({
    academyId: ctx.academyId,
    isBreak: input.isBreak,
    offeringId: input.isBreak ? null : (input.offeringId ?? null),
    dayOfWeek: input.dayOfWeek,
    startMinutes: input.startMinutes,
    endMinutes: input.endMinutes,
    room: input.room ?? null,
    semester: input.semester ?? null,
    effectiveFrom: input.effectiveFrom,
    effectiveTo: input.effectiveTo ?? null,
  });

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.TIMETABLE_SLOT_CREATED,
    metadata: { slotId: slot.id },
  });

  return slot;
}

interface UpdateSlotInput {
  isBreak?: boolean;
  offeringId?: string | null;
  dayOfWeek?: number;
  startMinutes?: number;
  endMinutes?: number;
  room?: string | null;
  semester?: string | null;
  effectiveFrom?: Date;
  effectiveTo?: Date | null;
}

async function update(ctx: ActorContext, slotId: string, input: UpdateSlotInput) {
  const existing = await timetableRepository.findByIdAndAcademy(slotId, ctx.academyId);
  if (!existing) throw new NotFoundError('Timetable slot not found in your academy.');

  const merged: SlotFields = {
    isBreak: input.isBreak ?? existing.isBreak,
    offeringId: input.offeringId !== undefined ? input.offeringId : existing.offeringId,
    dayOfWeek: input.dayOfWeek ?? existing.dayOfWeek,
    startMinutes: input.startMinutes ?? existing.startMinutes,
    endMinutes: input.endMinutes ?? existing.endMinutes,
    room: input.room !== undefined ? input.room : existing.room,
    semester: input.semester !== undefined ? input.semester : existing.semester,
    effectiveFrom: input.effectiveFrom ?? existing.effectiveFrom,
    effectiveTo: input.effectiveTo !== undefined ? input.effectiveTo : existing.effectiveTo,
  };

  if (merged.endMinutes <= merged.startMinutes) {
    throw new BadRequestError('endMinutes must be after startMinutes.');
  }
  if (merged.isBreak && merged.offeringId) {
    throw new BadRequestError('A break slot cannot reference a class offering.');
  }
  if (!merged.isBreak && !merged.offeringId) {
    throw new BadRequestError('offeringId is required unless isBreak is true.');
  }
  if (merged.effectiveTo && merged.effectiveTo < merged.effectiveFrom) {
    throw new BadRequestError('effectiveTo cannot be before effectiveFrom.');
  }

  const { teacherId, sectionId } = await resolveOfferingContext(ctx.academyId, merged.offeringId);
  await assertNoConflict(ctx, { ...merged, teacherId, sectionId }, slotId);

  const updated = await timetableRepository.update(slotId, {
    isBreak: merged.isBreak,
    offeringId: merged.isBreak ? null : merged.offeringId,
    dayOfWeek: merged.dayOfWeek,
    startMinutes: merged.startMinutes,
    endMinutes: merged.endMinutes,
    room: merged.room,
    semester: merged.semester,
    effectiveFrom: merged.effectiveFrom,
    effectiveTo: merged.effectiveTo,
  });

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.TIMETABLE_SLOT_UPDATED,
    metadata: { slotId },
  });

  return updated;
}

async function remove(ctx: ActorContext, slotId: string) {
  const existing = await timetableRepository.findByIdAndAcademy(slotId, ctx.academyId);
  if (!existing) throw new NotFoundError('Timetable slot not found in your academy.');

  await timetableRepository.delete(slotId);

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.TIMETABLE_SLOT_DELETED,
    metadata: { slotId },
  });
}

interface ListFilters {
  dayOfWeek?: number;
  studentId?: string;
}

async function list(ctx: ActorContext, filters: ListFilters) {
  if (ctx.role === 'ADMIN') {
    return timetableRepository.findManyByAcademy(ctx.academyId, filters.dayOfWeek);
  }

  if (ctx.role === 'TEACHER') {
    return timetableRepository.findManyByTeacher(ctx.academyId, ctx.userId, filters.dayOfWeek);
  }

  let targetStudentId = ctx.userId;
  if (ctx.role === 'PARENT') {
    if (!filters.studentId) {
      throw new BadRequestError('studentId query parameter is required for parent accounts.');
    }
    const linked = await parentChildLinkRepository.existsLink(ctx.userId, filters.studentId);
    if (!linked) {
      throw new ForbiddenError('You can only view the timetable for your linked children.');
    }
    targetStudentId = filters.studentId;
  } else if (ctx.role === 'STUDENT' && filters.studentId && filters.studentId !== ctx.userId) {
    throw new ForbiddenError('You can only view your own timetable.');
  }

  const student = await userRepository.findById(targetStudentId);
  if (!student || student.role !== 'STUDENT' || student.academyId !== ctx.academyId) {
    throw new NotFoundError('Student not found in your academy.');
  }

  const sectionIds = await classSectionRepository.findSectionIdsForStudent(targetStudentId);
  if (sectionIds.length === 0) return [];

  return timetableRepository.findManyBySectionIds(ctx.academyId, sectionIds, filters.dayOfWeek);
}

export const timetableService = {
  create,
  update,
  remove,
  list,
};
