import { AccountStatus, UserRole } from '@prisma/client';
import { env } from '../config/env';
import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, ConflictError, ForbiddenError, NotFoundError, UnauthorizedError } from '../exceptions/AppError';
import { academyRepository } from '../repositories/academy.repository';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { passwordResetTokenRepository } from '../repositories/passwordResetToken.repository';
import { refreshTokenRepository } from '../repositories/refreshToken.repository';
import { securityQuestionRepository } from '../repositories/securityQuestion.repository';
import { userRepository } from '../repositories/user.repository';
import { sendPasswordResetEmail } from './email.service';
import { RequestMeta, tokenService } from './token.service';
import { generateAcademyCode } from '../utils/academyCode';
import { comparePassword, hashPassword } from '../utils/password';
import { generateRawToken, hashToken } from '../utils/tokenHash';

const GENERIC_INVALID_CREDENTIALS = 'Invalid credentials. Check your email and password.';

export interface RegisterInput {
  fullName: string;
  email: string;
  password: string;
  phoneNumber: string;
  role: UserRole;
  academyName?: string;
  academyAddress?: string;
  academyPhone?: string;
  academyCode?: string;
  securityQuestion?: string;
  securityAnswer?: string;
}

async function resolveAcademyCode(): Promise<string> {
  let code = generateAcademyCode();
  // Extremely unlikely to collide (5 chars, 32-symbol alphabet ~33M combos),
  // but loop defensively rather than trust probability alone.
  while (await academyRepository.codeExists(code)) {
    code = generateAcademyCode();
  }
  return code;
}

async function register(input: RegisterInput, meta: RequestMeta) {
  if (await userRepository.emailExists(input.email)) {
    throw new ConflictError('An account with this email already exists.');
  }

  let academyId: string;
  if (input.role === 'ADMIN') {
    const code = await resolveAcademyCode();
    const academy = await academyRepository.create({
      name: input.academyName!.trim(),
      address: input.academyAddress?.trim(),
      phone: input.academyPhone?.trim(),
      code,
    });
    academyId = academy.id;
  } else {
    const academy = await academyRepository.findByCode(input.academyCode!);
    if (!academy) {
      throw new BadRequestError('Invalid academy code. Ask your academy admin for the correct join code.');
    }
    academyId = academy.id;
  }

  const passwordHash = await hashPassword(input.password);
  const accountStatus: AccountStatus = input.role === 'ADMIN' ? 'ACTIVE' : 'PENDING';

  const user = await userRepository.create({
    fullName: input.fullName,
    email: input.email,
    passwordHash,
    phoneNumber: input.phoneNumber,
    role: input.role,
    accountStatus,
    academy: { connect: { id: academyId } },
    joiningDate: new Date(),
  });

  if (input.securityQuestion && input.securityAnswer) {
    await setSecurityQuestion(user.id, input.securityQuestion, input.securityAnswer);
  }

  await auditLogRepository.record({
    userId: user.id,
    action: AUDIT_ACTIONS.REGISTER,
    metadata: { role: user.role, accountStatus: user.accountStatus },
    ipAddress: meta.ipAddress,
    userAgent: meta.userAgent,
  });

  if (accountStatus !== 'ACTIVE') {
    return { user, tokens: null as null };
  }

  const tokens = await tokenService.issueTokenPair(user, meta);
  return { user, tokens };
}

async function login(email: string, password: string, meta: RequestMeta) {
  const user = await userRepository.findByEmail(email);

  if (!user) {
    await auditLogRepository.record({
      action: AUDIT_ACTIONS.LOGIN_FAILURE,
      metadata: { email, reason: 'no_such_user' },
      ipAddress: meta.ipAddress,
      userAgent: meta.userAgent,
    });
    throw new UnauthorizedError(GENERIC_INVALID_CREDENTIALS);
  }

  const passwordMatches = await comparePassword(password, user.passwordHash);
  if (!passwordMatches) {
    await auditLogRepository.record({
      userId: user.id,
      action: AUDIT_ACTIONS.LOGIN_FAILURE,
      metadata: { reason: 'bad_password' },
      ipAddress: meta.ipAddress,
      userAgent: meta.userAgent,
    });
    throw new UnauthorizedError(GENERIC_INVALID_CREDENTIALS);
  }

  if (user.accountStatus === 'PENDING') {
    throw new ForbiddenError('Your account is pending admin approval.');
  }
  if (user.accountStatus === 'REJECTED') {
    throw new ForbiddenError('Your account request was rejected. Contact your admin.');
  }

  const tokens = await tokenService.issueTokenPair(user, meta);
  await auditLogRepository.record({
    userId: user.id,
    action: AUDIT_ACTIONS.LOGIN_SUCCESS,
    ipAddress: meta.ipAddress,
    userAgent: meta.userAgent,
  });

  return { user, tokens };
}

async function refresh(rawRefreshToken: string, meta: RequestMeta) {
  const { tokenPair, user } = await tokenService.rotateRefreshToken(rawRefreshToken, meta);
  await auditLogRepository.record({
    userId: user.id,
    action: AUDIT_ACTIONS.TOKEN_REFRESH,
    ipAddress: meta.ipAddress,
    userAgent: meta.userAgent,
  });
  return { user, tokens: tokenPair };
}

async function logout(userId: string, rawRefreshToken: string, meta: RequestMeta): Promise<void> {
  await tokenService.revokeRefreshToken(rawRefreshToken);
  await auditLogRepository.record({
    userId,
    action: AUDIT_ACTIONS.LOGOUT,
    ipAddress: meta.ipAddress,
    userAgent: meta.userAgent,
  });
}

/** Always resolves without revealing whether the email exists (user-enumeration mitigation). */
async function forgotPassword(email: string, meta: RequestMeta): Promise<void> {
  const user = await userRepository.findByEmail(email);
  if (!user) return;

  await passwordResetTokenRepository.invalidateAllForUser(user.id);

  const rawToken = generateRawToken();
  const expiresAt = new Date(Date.now() + env.PASSWORD_RESET_TOKEN_EXPIRES_MIN * 60 * 1000);
  await passwordResetTokenRepository.create(user.id, hashToken(rawToken), expiresAt);

  const resetLink = `${env.CLIENT_RESET_PASSWORD_URL}?token=${rawToken}`;
  await sendPasswordResetEmail(user.email, resetLink, env.PASSWORD_RESET_TOKEN_EXPIRES_MIN);

  await auditLogRepository.record({
    userId: user.id,
    action: AUDIT_ACTIONS.PASSWORD_RESET_REQUESTED,
    ipAddress: meta.ipAddress,
    userAgent: meta.userAgent,
  });
}

async function resetPassword(rawToken: string, newPassword: string, meta: RequestMeta): Promise<void> {
  const record = await passwordResetTokenRepository.findByHash(hashToken(rawToken));

  if (!record || record.usedAt || record.expiresAt.getTime() < Date.now()) {
    throw new BadRequestError('This password reset link is invalid or has expired.');
  }

  const passwordHash = await hashPassword(newPassword);
  await userRepository.update(record.userId, { passwordHash });
  await passwordResetTokenRepository.markUsed(record.id);
  await Promise.all([
    passwordResetTokenRepository.invalidateAllForUser(record.userId),
    refreshTokenRepository.revokeAllForUser(record.userId), // force logout everywhere
    auditLogRepository.record({
      userId: record.userId,
      action: AUDIT_ACTIONS.PASSWORD_RESET_COMPLETED,
      ipAddress: meta.ipAddress,
      userAgent: meta.userAgent,
    }),
  ]);
}

async function lookupAcademyByCode(code: string) {
  const academy = await academyRepository.findByCode(code);
  if (!academy) {
    throw new NotFoundError('No academy found with this code.');
  }
  return { id: academy.id, name: academy.name, code: academy.code, logoUrl: academy.logoUrl };
}

async function setSecurityQuestion(userId: string, question: string, answer: string): Promise<void> {
  const answerHash = await hashPassword(normalizeAnswer(answer));
  await securityQuestionRepository.upsert(userId, question, answerHash);
  await auditLogRepository.record({ userId, action: AUDIT_ACTIONS.SECURITY_QUESTION_SET });
}

async function getSecurityQuestionForEmail(email: string): Promise<{ question: string }> {
  const user = await userRepository.findByEmail(email);
  const securityQuestion = user ? await securityQuestionRepository.findByUserId(user.id) : null;
  if (!user || !securityQuestion) {
    throw new NotFoundError('No recovery question is set up for this account.');
  }
  return { question: securityQuestion.question };
}

async function verifySecurityAnswer(email: string, answer: string): Promise<boolean> {
  const user = await userRepository.findByEmail(email);
  if (!user) return false;
  const securityQuestion = await securityQuestionRepository.findByUserId(user.id);
  if (!securityQuestion) return false;
  return comparePassword(normalizeAnswer(answer), securityQuestion.answerHash);
}

async function recoverViaSecurityAnswer(
  email: string,
  answer: string,
  newPassword: string,
  meta: RequestMeta,
): Promise<void> {
  const user = await userRepository.findByEmail(email);
  if (!user) {
    throw new BadRequestError('Invalid recovery request.');
  }
  const securityQuestion = await securityQuestionRepository.findByUserId(user.id);
  if (!securityQuestion) {
    throw new BadRequestError('Invalid recovery request.');
  }

  const answerMatches = await comparePassword(normalizeAnswer(answer), securityQuestion.answerHash);
  if (!answerMatches) {
    throw new UnauthorizedError('Incorrect answer to the security question.');
  }

  const passwordHash = await hashPassword(newPassword);
  await userRepository.update(user.id, { passwordHash });
  await refreshTokenRepository.revokeAllForUser(user.id); // force logout everywhere

  await auditLogRepository.record({
    userId: user.id,
    action: AUDIT_ACTIONS.SECURITY_QUESTION_RECOVERY,
    ipAddress: meta.ipAddress,
    userAgent: meta.userAgent,
  });
}

function normalizeAnswer(answer: string): string {
  return answer.trim().toLowerCase();
}

/**
 * Change password while already signed in. Unlike the legacy Firebase flow
 * (which only required an active session, not the current password
 * itself, to call `updatePassword`), this requires and verifies
 * `currentPassword` — a hijacked access token alone can't silently take
 * over the account's credential. Revokes every refresh token afterward,
 * same as the other password-change paths, forcing re-login everywhere.
 */
async function changePassword(userId: string, currentPassword: string, newPassword: string, meta: RequestMeta): Promise<void> {
  const user = await userRepository.findById(userId);
  if (!user) throw new UnauthorizedError('Account no longer exists.');

  const matches = await comparePassword(currentPassword, user.passwordHash);
  if (!matches) {
    throw new UnauthorizedError('Current password is incorrect.');
  }

  const passwordHash = await hashPassword(newPassword);
  await userRepository.update(userId, { passwordHash });
  await refreshTokenRepository.revokeAllForUser(userId);

  await auditLogRepository.record({
    userId,
    action: AUDIT_ACTIONS.PASSWORD_CHANGED,
    ipAddress: meta.ipAddress,
    userAgent: meta.userAgent,
  });
}

/**
 * Self-service fix for an account scoped to the wrong academy (e.g. a
 * mistyped/stale join code at signup) — ported from the legacy
 * `AuthService.relinkAcademy`. Any signed-in user may update their own
 * academy link; there's nothing else to authorize since this only ever
 * touches the caller's own row.
 */
async function relinkAcademy(userId: string, code: string, meta: RequestMeta) {
  const academy = await academyRepository.findByCode(code.trim().toUpperCase());
  if (!academy) {
    throw new NotFoundError('Invalid academy code.');
  }

  const updated = await userRepository.update(userId, { academy: { connect: { id: academy.id } } });

  await auditLogRepository.record({
    userId,
    action: AUDIT_ACTIONS.ACADEMY_RELINKED,
    metadata: { academyId: academy.id },
    ipAddress: meta.ipAddress,
    userAgent: meta.userAgent,
  });

  return updated;
}

export const authService = {
  register,
  login,
  refresh,
  logout,
  forgotPassword,
  resetPassword,
  lookupAcademyByCode,
  setSecurityQuestion,
  getSecurityQuestionForEmail,
  verifySecurityAnswer,
  recoverViaSecurityAnswer,
  changePassword,
  relinkAcademy,
};
