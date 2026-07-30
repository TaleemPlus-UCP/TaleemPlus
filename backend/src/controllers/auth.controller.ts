import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { UnauthorizedError } from '../exceptions/AppError';
import { authService } from '../services/auth.service';
import { userRepository } from '../repositories/user.repository';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';
import { getRequestMeta } from '../utils/requestMeta';
import { toUserResponse } from '../utils/serializers';

export const register = asyncHandler(async (req: Request, res: Response) => {
  const { user, tokens } = await authService.register(req.body, getRequestMeta(req));

  const message =
    tokens === null
      ? 'Registration submitted. Your account is pending admin approval.'
      : 'Registration successful.';

  sendSuccess(res, HttpStatus.CREATED, message, { user: toUserResponse(user), tokens });
});

export const login = asyncHandler(async (req: Request, res: Response) => {
  const { email, password } = req.body;
  const { user, tokens } = await authService.login(email, password, getRequestMeta(req));
  sendSuccess(res, HttpStatus.OK, 'Login successful.', { user: toUserResponse(user), tokens });
});

export const refresh = asyncHandler(async (req: Request, res: Response) => {
  const { refreshToken } = req.body;
  const { user, tokens } = await authService.refresh(refreshToken, getRequestMeta(req));
  sendSuccess(res, HttpStatus.OK, 'Token refreshed.', { user: toUserResponse(user), tokens });
});

export const logout = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new UnauthorizedError('Authentication required.');
  const { refreshToken } = req.body;
  await authService.logout(req.user.id, refreshToken, getRequestMeta(req));
  sendSuccess(res, HttpStatus.OK, 'Logged out successfully.', null);
});

export const me = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new UnauthorizedError('Authentication required.');
  const user = await userRepository.findById(req.user.id);
  if (!user) throw new UnauthorizedError('Account no longer exists.');
  sendSuccess(res, HttpStatus.OK, 'Current user profile.', { user: toUserResponse(user) });
});

export const forgotPassword = asyncHandler(async (req: Request, res: Response) => {
  const { email } = req.body;
  await authService.forgotPassword(email, getRequestMeta(req));
  sendSuccess(res, HttpStatus.OK, 'If that email is registered, a reset link has been sent.', null);
});

export const resetPassword = asyncHandler(async (req: Request, res: Response) => {
  const { token, newPassword } = req.body;
  await authService.resetPassword(token, newPassword, getRequestMeta(req));
  sendSuccess(res, HttpStatus.OK, 'Password has been reset. Please log in again.', null);
});

export const lookupAcademy = asyncHandler(async (req: Request, res: Response) => {
  const { code } = req.query as { code: string };
  const academy = await authService.lookupAcademyByCode(code);
  sendSuccess(res, HttpStatus.OK, 'Academy found.', { academy });
});

export const setSecurityQuestion = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new UnauthorizedError('Authentication required.');
  const { question, answer } = req.body;
  await authService.setSecurityQuestion(req.user.id, question, answer);
  sendSuccess(res, HttpStatus.OK, 'Security question saved.', null);
});

export const getSecurityQuestion = asyncHandler(async (req: Request, res: Response) => {
  const { email } = req.query as { email: string };
  const result = await authService.getSecurityQuestionForEmail(email);
  sendSuccess(res, HttpStatus.OK, 'Security question found.', result);
});

export const verifySecurityAnswer = asyncHandler(async (req: Request, res: Response) => {
  const { email, answer } = req.body;
  const isCorrect = await authService.verifySecurityAnswer(email, answer);
  sendSuccess(res, HttpStatus.OK, isCorrect ? 'Answer is correct.' : 'Answer is incorrect.', { isCorrect });
});

export const recoverViaSecurityAnswer = asyncHandler(async (req: Request, res: Response) => {
  const { email, answer, newPassword } = req.body;
  await authService.recoverViaSecurityAnswer(email, answer, newPassword, getRequestMeta(req));
  sendSuccess(res, HttpStatus.OK, 'Password has been reset. Please log in again.', null);
});

export const changePassword = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new UnauthorizedError('Authentication required.');
  const { currentPassword, newPassword } = req.body;
  await authService.changePassword(req.user.id, currentPassword, newPassword, getRequestMeta(req));
  sendSuccess(res, HttpStatus.OK, 'Password changed. Please log in again.', null);
});

export const relinkAcademy = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user) throw new UnauthorizedError('Authentication required.');
  const user = await authService.relinkAcademy(req.user.id, req.body.code, getRequestMeta(req));
  sendSuccess(res, HttpStatus.OK, 'Academy link updated.', { user: toUserResponse(user) });
});
