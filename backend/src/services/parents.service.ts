import { UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { ConflictError, NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { parentChildLinkRepository } from '../repositories/parentChildLink.repository';
import { userRepository } from '../repositories/user.repository';
import { buildPaginationMeta } from '../utils/apiResponse';

interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

interface Pagination {
  page: number;
  limit: number;
}

async function listChildren(ctx: ActorContext) {
  return parentChildLinkRepository.findChildrenForParent(ctx.userId);
}

interface LinkChildInput {
  email?: string;
  studentId?: string;
}

/** Accepts either an exact-email lookup (manual entry) or a studentId (picked from a search result) — both end up at the same link operation. */
async function linkChild(ctx: ActorContext, input: LinkChildInput) {
  const student = input.studentId
    ? await userRepository.findByIdAndAcademy(input.studentId, ctx.academyId)
    : await userRepository.findByEmail(input.email!);

  if (!student || student.role !== 'STUDENT' || student.academyId !== ctx.academyId) {
    throw new NotFoundError('No student found with that email in your academy.');
  }

  if (await parentChildLinkRepository.existsLink(ctx.userId, student.id)) {
    throw new ConflictError('This child is already linked to your account.');
  }

  await parentChildLinkRepository.create(ctx.userId, student.id);

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.PARENT_CHILD_LINKED,
    metadata: { childId: student.id },
  });

  return student;
}

async function unlinkChild(ctx: ActorContext, childId: string) {
  const linked = await parentChildLinkRepository.existsLink(ctx.userId, childId);
  if (!linked) throw new NotFoundError('This child is not linked to your account.');

  await parentChildLinkRepository.delete(ctx.userId, childId);

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.PARENT_CHILD_UNLINKED,
    metadata: { childId },
  });
}

async function searchStudents(ctx: ActorContext, query: string, pagination: Pagination) {
  const { items, total } = await userRepository.findManyByAcademyAndRole({
    academyId: ctx.academyId,
    role: 'STUDENT',
    search: query,
    ...pagination,
  });
  return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
}

export const parentsService = {
  listChildren,
  linkChild,
  unlinkChild,
  searchStudents,
};
