import { UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, NotFoundError } from '../exceptions/AppError';
import { announcementRepository } from '../repositories/announcement.repository';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { userRepository } from '../repositories/user.repository';
import { buildPaginationMeta } from '../utils/apiResponse';
import { notificationsService } from './notifications.service';

const ALL_TARGETABLE_ROLES: UserRole[] = ['TEACHER', 'STUDENT', 'PARENT'];

interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

interface Pagination {
  page: number;
  limit: number;
}

async function list(ctx: ActorContext, pagination: Pagination) {
  const { items, total } =
    ctx.role === 'ADMIN'
      ? await announcementRepository.findManyByAcademy(ctx.academyId, pagination)
      : await announcementRepository.findManyForRole(ctx.academyId, ctx.role, pagination);
  return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
}

/** Best-effort fan-out, mirroring the legacy app's `_notifyTargets` — a delivery failure never blocks the post itself. */
async function notifyTargets(ctx: ActorContext, title: string, isForAll: boolean, targetRoles: UserRole[]) {
  const roles = isForAll ? ALL_TARGETABLE_ROLES : targetRoles;
  const recipientIds = new Set<string>();

  for (const role of roles) {
    const users = await userRepository.findApprovedByRole(ctx.academyId, role);
    for (const user of users) {
      if (user.id !== ctx.userId) recipientIds.add(user.id);
    }
  }

  if (recipientIds.size > 0) {
    await notificationsService.notifyMany(
      ctx.academyId,
      Array.from(recipientIds),
      'New Announcement',
      title,
      'ANNOUNCEMENT',
    );
  }
}

interface CreateAnnouncementInput {
  title: string;
  message: string;
  isForAll: boolean;
  targetRoles: UserRole[];
}

async function create(ctx: ActorContext, input: CreateAnnouncementInput) {
  const announcement = await announcementRepository.create({
    academyId: ctx.academyId,
    title: input.title,
    message: input.message,
    isForAll: input.isForAll,
    targetRoles: input.isForAll ? [] : input.targetRoles,
    createdById: ctx.userId,
  });

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.ANNOUNCEMENT_CREATED,
    metadata: { announcementId: announcement.id },
  });

  await notifyTargets(ctx, input.title, input.isForAll, input.targetRoles);

  return announcement;
}

interface UpdateAnnouncementInput {
  title?: string;
  message?: string;
  isForAll?: boolean;
  targetRoles?: UserRole[];
}

async function update(ctx: ActorContext, announcementId: string, input: UpdateAnnouncementInput) {
  const existing = await announcementRepository.findByIdAndAcademy(announcementId, ctx.academyId);
  if (!existing) throw new NotFoundError('Announcement not found in your academy.');

  const isForAll = input.isForAll ?? existing.isForAll;
  const targetRoles = input.targetRoles ?? existing.targetRoles;
  if (!isForAll && targetRoles.length === 0) {
    throw new BadRequestError('targetRoles must include at least one role unless isForAll is true.');
  }

  const updated = await announcementRepository.update(announcementId, {
    title: input.title ?? existing.title,
    message: input.message ?? existing.message,
    isForAll,
    targetRoles: isForAll ? [] : targetRoles,
  });

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.ANNOUNCEMENT_UPDATED,
    metadata: { announcementId },
  });

  return updated;
}

async function remove(ctx: ActorContext, announcementId: string) {
  const existing = await announcementRepository.findByIdAndAcademy(announcementId, ctx.academyId);
  if (!existing) throw new NotFoundError('Announcement not found in your academy.');

  await announcementRepository.delete(announcementId);

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.ANNOUNCEMENT_DELETED,
    metadata: { announcementId },
  });
}

export const announcementsService = {
  list,
  create,
  update,
  remove,
};
