import { Prisma } from '@prisma/client';
import { prisma } from '../config/database';
import { logger } from '../config/logger';

interface RecordAuditLogInput {
  userId?: string | null;
  action: string;
  metadata?: Prisma.InputJsonValue;
  ipAddress?: string;
  userAgent?: string;
}

export const auditLogRepository = {
  /**
   * Audit logging must never break the request it's observing — a failed
   * write here is logged and swallowed rather than propagated.
   */
  async record(input: RecordAuditLogInput): Promise<void> {
    try {
      await prisma.auditLog.create({
        data: {
          userId: input.userId ?? null,
          action: input.action,
          metadata: input.metadata,
          ipAddress: input.ipAddress,
          userAgent: input.userAgent,
        },
      });
    } catch (error) {
      logger.error(`Failed to write audit log for action ${input.action}: ${(error as Error).message}`);
    }
  },
};
