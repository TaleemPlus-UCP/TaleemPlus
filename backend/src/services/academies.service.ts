import { UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { academyRepository } from '../repositories/academy.repository';
import { auditLogRepository } from '../repositories/auditLog.repository';

interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

interface UpdateAcademyInput {
  name?: string;
  address?: string;
  phone?: string;
  logoUrl?: string;
}

async function updateMine(ctx: ActorContext, input: UpdateAcademyInput) {
  const updated = await academyRepository.update(ctx.academyId, input);

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.ACADEMY_UPDATED,
    metadata: { academyId: ctx.academyId },
  });

  return updated;
}

export const academiesService = {
  updateMine,
};
