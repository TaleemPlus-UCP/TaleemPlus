import { UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, ConflictError, NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { refreshTokenRepository } from '../repositories/refreshToken.repository';
import { userRepository } from '../repositories/user.repository';
import { sendAccountApprovedEmail, sendAccountRejectedEmail } from './email.service';
import { notificationsService } from './notifications.service';
import { logger } from '../config/logger';
import { buildPaginationMeta } from '../utils/apiResponse';
import { hashPassword } from '../utils/password';

interface ActorContext {
  adminId: string;
  academyId: string;
}

interface Pagination {
  page: number;
  limit: number;
}

async function listPending(ctx: ActorContext, role: UserRole | undefined, pagination: Pagination) {
  const { items, total } = await userRepository.findPendingByAcademy({
    academyId: ctx.academyId,
    role,
    ...pagination,
  });
  return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
}

async function approve(ctx: ActorContext, userId: string) {
  const user = await userRepository.findByIdAndAcademy(userId, ctx.academyId);
  if (!user) throw new NotFoundError('User not found in your academy.');
  if (user.accountStatus !== 'PENDING') {
    throw new BadRequestError('This account is not pending approval.');
  }

  const updated = await userRepository.update(user.id, { accountStatus: 'ACTIVE' });

  await auditLogRepository.record({
    userId: ctx.adminId,
    action: AUDIT_ACTIONS.USER_APPROVED,
    metadata: { targetUserId: user.id },
  });

  try {
    await sendAccountApprovedEmail(updated.email, updated.fullName);
  } catch (error) {
    logger.warn(`Failed to send approval email to ${updated.email}: ${(error as Error).message}`);
  }

  await notificationsService.notifyUser(
    ctx.academyId,
    updated.id,
    'Account Approved',
    `Your account has been approved${updated.academy ? ` by ${updated.academy.name}` : ''}. You can now log in.`,
    'APPROVAL',
  );

  return updated;
}

async function reject(ctx: ActorContext, userId: string) {
  const user = await userRepository.findByIdAndAcademy(userId, ctx.academyId);
  if (!user) throw new NotFoundError('User not found in your academy.');
  if (user.accountStatus !== 'PENDING') {
    throw new BadRequestError('This account is not pending approval.');
  }

  const updated = await userRepository.update(user.id, { accountStatus: 'REJECTED' });

  await auditLogRepository.record({
    userId: ctx.adminId,
    action: AUDIT_ACTIONS.USER_REJECTED,
    metadata: { targetUserId: user.id },
  });

  try {
    await sendAccountRejectedEmail(updated.email, updated.fullName, updated.academy?.name);
  } catch (error) {
    logger.warn(`Failed to send rejection email to ${updated.email}: ${(error as Error).message}`);
  }

  await notificationsService.notifyUser(
    ctx.academyId,
    updated.id,
    'Account Rejected',
    `Your signup request for ${updated.academy?.name ?? 'this academy'} was not approved.`,
    'APPROVAL',
  );

  return updated;
}

async function listByRole(
  ctx: ActorContext,
  role: UserRole,
  search: string | undefined,
  pagination: Pagination,
) {
  const { items, total } = await userRepository.findManyByAcademyAndRole({
    academyId: ctx.academyId,
    role,
    search,
    ...pagination,
  });
  return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
}

export interface CreateUserByAdminInput {
  fullName: string;
  email: string;
  password: string;
  phoneNumber: string;
  role: UserRole;
  extraInfo?: string;
  joiningDate?: Date;
  assignedSections?: string[];
}

async function createByAdmin(ctx: ActorContext, input: CreateUserByAdminInput) {
  if (await userRepository.emailExists(input.email)) {
    throw new ConflictError('An account with this email already exists.');
  }

  const passwordHash = await hashPassword(input.password);

  const user = await userRepository.create({
    fullName: input.fullName,
    email: input.email,
    passwordHash,
    phoneNumber: input.phoneNumber,
    role: input.role,
    accountStatus: 'ACTIVE',
    academy: { connect: { id: ctx.academyId } },
    extraInfo: input.extraInfo,
    joiningDate: input.joiningDate ?? new Date(),
    assignedSections: input.assignedSections ?? [],
  });

  await auditLogRepository.record({
    userId: ctx.adminId,
    action: AUDIT_ACTIONS.USER_CREATED_BY_ADMIN,
    metadata: { targetUserId: user.id, role: user.role },
  });

  return user;
}

async function getOne(ctx: ActorContext, userId: string) {
  const user = await userRepository.findByIdAndAcademy(userId, ctx.academyId);
  if (!user) throw new NotFoundError('User not found in your academy.');
  return user;
}

export interface UpdateUserInput {
  fullName?: string;
  phoneNumber?: string;
  extraInfo?: string;
  joiningDate?: Date;
  assignedSections?: string[];
}

async function update(ctx: ActorContext, userId: string, input: UpdateUserInput) {
  const user = await userRepository.findByIdAndAcademy(userId, ctx.academyId);
  if (!user) throw new NotFoundError('User not found in your academy.');

  const updated = await userRepository.update(user.id, input);

  await auditLogRepository.record({
    userId: ctx.adminId,
    action: AUDIT_ACTIONS.USER_UPDATED,
    metadata: { targetUserId: user.id },
  });

  return updated;
}

async function remove(ctx: ActorContext, userId: string) {
  const user = await userRepository.findByIdAndAcademy(userId, ctx.academyId);
  if (!user) throw new NotFoundError('User not found in your academy.');

  await userRepository.softDelete(user.id);
  await refreshTokenRepository.revokeAllForUser(user.id); // kick out any active session immediately

  await auditLogRepository.record({
    userId: ctx.adminId,
    action: AUDIT_ACTIONS.USER_DELETED,
    metadata: { targetUserId: user.id },
  });
}

export const usersService = {
  listPending,
  approve,
  reject,
  listByRole,
  createByAdmin,
  getOne,
  update,
  remove,
};
