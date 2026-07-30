import { prisma } from '../config/database';

interface CreateRefreshTokenInput {
  userId: string;
  tokenHash: string;
  expiresAt: Date;
  userAgent?: string;
  ipAddress?: string;
}

export const refreshTokenRepository = {
  create(data: CreateRefreshTokenInput) {
    return prisma.refreshToken.create({ data });
  },

  findByHash(tokenHash: string) {
    return prisma.refreshToken.findUnique({ where: { tokenHash }, include: { user: { include: { academy: true } } } });
  },

  revoke(id: string, replacedByTokenHash?: string) {
    return prisma.refreshToken.update({
      where: { id },
      data: { revokedAt: new Date(), replacedByTokenHash },
    });
  },

  revokeAllForUser(userId: string) {
    return prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  },

  deleteExpired() {
    return prisma.refreshToken.deleteMany({ where: { expiresAt: { lt: new Date() } } });
  },
};
