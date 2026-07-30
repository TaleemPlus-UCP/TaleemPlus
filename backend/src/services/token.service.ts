import { User } from '@prisma/client';
import { env } from '../config/env';
import { UnauthorizedError, ForbiddenError } from '../exceptions/AppError';
import { refreshTokenRepository } from '../repositories/refreshToken.repository';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { AUDIT_ACTIONS } from '../constants/roles';
import { parseDurationToMs } from '../utils/duration';
import { generateRawToken, hashToken } from '../utils/tokenHash';
import { signAccessToken } from '../utils/jwt';

export interface RequestMeta {
  ipAddress?: string;
  userAgent?: string;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  accessTokenExpiresIn: string;
  refreshTokenExpiresAt: Date;
}

async function issueTokenPair(user: User, meta: RequestMeta): Promise<TokenPair> {
  const accessToken = signAccessToken({
    sub: user.id,
    role: user.role,
    academyId: user.academyId,
    accountStatus: user.accountStatus,
  });

  const rawRefreshToken = generateRawToken();
  const refreshTokenExpiresAt = new Date(Date.now() + parseDurationToMs(env.JWT_REFRESH_EXPIRES_IN));

  await refreshTokenRepository.create({
    userId: user.id,
    tokenHash: hashToken(rawRefreshToken),
    expiresAt: refreshTokenExpiresAt,
    userAgent: meta.userAgent,
    ipAddress: meta.ipAddress,
  });

  return {
    accessToken,
    refreshToken: rawRefreshToken,
    accessTokenExpiresIn: env.JWT_ACCESS_EXPIRES_IN,
    refreshTokenExpiresAt,
  };
}

/**
 * Validates a raw refresh token, rotates it (old one revoked, new one
 * issued), and returns a fresh token pair plus the owning user. If a
 * previously-revoked/rotated token is presented again, that's a signal the
 * token was stolen — every other session for the user is killed and the
 * incident is audit-logged.
 */
async function rotateRefreshToken(rawRefreshToken: string, meta: RequestMeta) {
  const tokenHash = hashToken(rawRefreshToken);
  const existing = await refreshTokenRepository.findByHash(tokenHash);

  if (!existing) {
    throw new UnauthorizedError('Refresh token is invalid.');
  }

  if (existing.revokedAt) {
    await refreshTokenRepository.revokeAllForUser(existing.userId);
    await auditLogRepository.record({
      userId: existing.userId,
      action: AUDIT_ACTIONS.TOKEN_REUSE_DETECTED,
      ipAddress: meta.ipAddress,
      userAgent: meta.userAgent,
    });
    throw new UnauthorizedError('Refresh token has already been used. All sessions have been revoked for safety.');
  }

  if (existing.expiresAt.getTime() < Date.now()) {
    throw new UnauthorizedError('Refresh token has expired. Please log in again.');
  }

  const user = existing.user;
  if (user.deletedAt || user.accountStatus !== 'ACTIVE') {
    throw new ForbiddenError('Your account is not active.');
  }

  const newPair = await issueTokenPair(user, meta);
  await refreshTokenRepository.revoke(existing.id, hashToken(newPair.refreshToken));

  return { tokenPair: newPair, user };
}

async function revokeRefreshToken(rawRefreshToken: string): Promise<void> {
  const tokenHash = hashToken(rawRefreshToken);
  const existing = await refreshTokenRepository.findByHash(tokenHash);
  if (existing && !existing.revokedAt) {
    await refreshTokenRepository.revoke(existing.id);
  }
}

export const tokenService = {
  issueTokenPair,
  rotateRefreshToken,
  revokeRefreshToken,
};
