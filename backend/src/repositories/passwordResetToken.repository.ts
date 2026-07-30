import { prisma } from '../config/database';

export const passwordResetTokenRepository = {
  create(userId: string, tokenHash: string, expiresAt: Date) {
    return prisma.passwordResetToken.create({ data: { userId, tokenHash, expiresAt } });
  },

  findByHash(tokenHash: string) {
    return prisma.passwordResetToken.findUnique({ where: { tokenHash }, include: { user: true } });
  },

  markUsed(id: string) {
    return prisma.passwordResetToken.update({ where: { id }, data: { usedAt: new Date() } });
  },

  invalidateAllForUser(userId: string) {
    return prisma.passwordResetToken.updateMany({
      where: { userId, usedAt: null },
      data: { usedAt: new Date() },
    });
  },
};
