import { Router } from 'express';
import * as authController from '../controllers/auth.controller';
import { authenticate } from '../middlewares/authenticate';
import { authRateLimiter } from '../middlewares/rateLimiter';
import { validate } from '../middlewares/validate';
import {
  academyLookupSchema,
  changePasswordSchema,
  forgotPasswordSchema,
  loginSchema,
  recoverViaSecurityAnswerSchema,
  refreshTokenSchema,
  registerSchema,
  relinkAcademySchema,
  resetPasswordSchema,
  securityQuestionLookupSchema,
  setSecurityQuestionSchema,
  verifySecurityAnswerSchema,
} from '../validators/auth.validators';

export const authRouter = Router();

/**
 * @openapi
 * /auth/register:
 *   post:
 *     summary: Register a new account (admin creates an academy; teacher/student/parent join one by code)
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/RegisterRequest'
 *     responses:
 *       201:
 *         description: Registered. Admins receive tokens immediately; other roles start PENDING and receive no tokens until approved.
 *       409:
 *         description: Email already registered.
 *       422:
 *         description: Validation failed.
 */
authRouter.post('/register', authRateLimiter, validate({ body: registerSchema }), authController.register);

/**
 * @openapi
 * /auth/login:
 *   post:
 *     summary: Log in with email and password
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LoginRequest'
 *     responses:
 *       200:
 *         description: Login successful.
 *       401:
 *         description: Invalid credentials.
 *       403:
 *         description: Account pending approval or rejected.
 */
authRouter.post('/login', authRateLimiter, validate({ body: loginSchema }), authController.login);

/**
 * @openapi
 * /auth/refresh:
 *   post:
 *     summary: Exchange a refresh token for a new access/refresh token pair (rotates the refresh token)
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/RefreshRequest'
 *     responses:
 *       200:
 *         description: New token pair issued.
 *       401:
 *         description: Refresh token invalid, expired, or already used (reuse triggers session-wide revocation).
 */
authRouter.post('/refresh', validate({ body: refreshTokenSchema }), authController.refresh);

/**
 * @openapi
 * /auth/logout:
 *   post:
 *     summary: Revoke a refresh token (ends that session)
 *     tags: [Auth]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/RefreshRequest'
 *     responses:
 *       200:
 *         description: Logged out.
 *       401:
 *         description: Not authenticated.
 */
authRouter.post('/logout', authenticate, validate({ body: refreshTokenSchema }), authController.logout);

/**
 * @openapi
 * /auth/me:
 *   get:
 *     summary: Get the current authenticated user's profile
 *     tags: [Auth]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200:
 *         description: Current user profile.
 *       401:
 *         description: Not authenticated.
 */
authRouter.get('/me', authenticate, authController.me);

/**
 * @openapi
 * /auth/forgot-password:
 *   post:
 *     summary: Request a password reset email
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email]
 *             properties:
 *               email: { type: string, format: email }
 *     responses:
 *       200:
 *         description: Always returns success to avoid revealing whether the email is registered.
 */
authRouter.post(
  '/forgot-password',
  authRateLimiter,
  validate({ body: forgotPasswordSchema }),
  authController.forgotPassword,
);

/**
 * @openapi
 * /auth/reset-password:
 *   post:
 *     summary: Reset password using the token emailed by /auth/forgot-password
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [token, newPassword]
 *             properties:
 *               token: { type: string }
 *               newPassword: { type: string }
 *     responses:
 *       200:
 *         description: Password reset; all sessions revoked.
 *       400:
 *         description: Token invalid or expired.
 */
authRouter.post(
  '/reset-password',
  authRateLimiter,
  validate({ body: resetPasswordSchema }),
  authController.resetPassword,
);

/**
 * @openapi
 * /auth/academy:
 *   get:
 *     summary: Look up an academy by its human-friendly join code (used at signup)
 *     tags: [Auth]
 *     parameters:
 *       - in: query
 *         name: code
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: Academy found.
 *       404:
 *         description: No academy with that code.
 */
authRouter.get('/academy', validate({ query: academyLookupSchema }), authController.lookupAcademy);

/**
 * @openapi
 * /auth/security-question:
 *   post:
 *     summary: Set or replace the current user's security question (self-service recovery)
 *     tags: [Auth]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [question, answer]
 *             properties:
 *               question: { type: string }
 *               answer: { type: string }
 *     responses:
 *       200:
 *         description: Security question saved.
 *   get:
 *     summary: Get the security question configured for an email (pre-login recovery flow)
 *     tags: [Auth]
 *     parameters:
 *       - in: query
 *         name: email
 *         required: true
 *         schema: { type: string, format: email }
 *     responses:
 *       200:
 *         description: Security question found.
 *       404:
 *         description: No recovery question configured for this account.
 */
authRouter
  .route('/security-question')
  .get(validate({ query: securityQuestionLookupSchema }), authController.getSecurityQuestion)
  .post(authenticate, validate({ body: setSecurityQuestionSchema }), authController.setSecurityQuestion);

/**
 * @openapi
 * /auth/security-question/verify:
 *   post:
 *     summary: Check whether an answer matches the account's security question (does not change anything)
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, answer]
 *             properties:
 *               email: { type: string, format: email }
 *               answer: { type: string }
 *     responses:
 *       200:
 *         description: Returns { isCorrect } — always 200 to avoid leaking account existence via status code.
 */
authRouter.post(
  '/security-question/verify',
  authRateLimiter,
  validate({ body: verifySecurityAnswerSchema }),
  authController.verifySecurityAnswer,
);

/**
 * @openapi
 * /auth/security-question/recover:
 *   post:
 *     summary: Reset password by answering the security question (alternative to the email reset link)
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, answer, newPassword]
 *             properties:
 *               email: { type: string, format: email }
 *               answer: { type: string }
 *               newPassword: { type: string }
 *     responses:
 *       200:
 *         description: Password reset; all sessions revoked.
 *       400:
 *         description: No matching account/security question configured.
 *       401:
 *         description: Incorrect answer.
 */
authRouter.post(
  '/security-question/recover',
  authRateLimiter,
  validate({ body: recoverViaSecurityAnswerSchema }),
  authController.recoverViaSecurityAnswer,
);

/**
 * @openapi
 * /auth/change-password:
 *   post:
 *     summary: Change password while signed in (requires the current password; revokes every session afterward)
 *     tags: [Auth]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [currentPassword, newPassword]
 *             properties:
 *               currentPassword: { type: string }
 *               newPassword: { type: string }
 *     responses:
 *       200:
 *         description: Password changed; all sessions revoked, including the current one.
 *       401:
 *         description: Current password is incorrect.
 */
authRouter.post(
  '/change-password',
  authenticate,
  authRateLimiter,
  validate({ body: changePasswordSchema }),
  authController.changePassword,
);

/**
 * @openapi
 * /auth/relink-academy:
 *   post:
 *     summary: Self-service fix for an account scoped to the wrong academy — updates the caller's own academy link by join code
 *     tags: [Auth]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [code]
 *             properties:
 *               code: { type: string }
 *     responses:
 *       200:
 *         description: Academy link updated.
 *       404:
 *         description: Invalid academy code.
 */
authRouter.post('/relink-academy', authenticate, validate({ body: relinkAcademySchema }), authController.relinkAcademy);
