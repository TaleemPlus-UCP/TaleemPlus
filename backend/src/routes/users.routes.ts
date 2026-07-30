import { Router } from 'express';
import * as usersController from '../controllers/users.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import {
  createUserByAdminSchema,
  listUsersQuerySchema,
  pendingUsersQuerySchema,
  updateUserSchema,
} from '../validators/user.validators';

export const usersRouter = Router();

// Every route in this module is admin-only and scoped to the admin's own academy.
usersRouter.use(authenticate, requireActiveAccount, requireRoles('ADMIN'));

/**
 * @openapi
 * /users/pending:
 *   get:
 *     summary: List users awaiting approval in the admin's academy
 *     tags: [Users]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: role
 *         schema: { type: string, enum: [TEACHER, STUDENT, PARENT] }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Paginated list of PENDING users.
 */
usersRouter.get('/pending', validate({ query: pendingUsersQuerySchema }), usersController.listPending);

/**
 * @openapi
 * /users/{id}/approve:
 *   post:
 *     summary: Approve a pending user (account_status PENDING -> ACTIVE)
 *     tags: [Users]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: User approved.
 *       400:
 *         description: Account is not PENDING.
 *       404:
 *         description: No such user in this academy.
 */
usersRouter.post('/:id/approve', validate({ params: idParamSchema }), usersController.approve);

/**
 * @openapi
 * /users/{id}/reject:
 *   post:
 *     summary: Reject a pending user (account_status PENDING -> REJECTED)
 *     tags: [Users]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200:
 *         description: User rejected.
 *       400:
 *         description: Account is not PENDING.
 *       404:
 *         description: No such user in this academy.
 */
usersRouter.post('/:id/reject', validate({ params: idParamSchema }), usersController.reject);

/**
 * @openapi
 * /users:
 *   get:
 *     summary: List active/rejected/pending users of one role in the admin's academy, with search + pagination
 *     tags: [Users]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: role
 *         required: true
 *         schema: { type: string, enum: [TEACHER, STUDENT, PARENT] }
 *       - in: query
 *         name: search
 *         schema: { type: string }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Paginated list of users.
 *   post:
 *     summary: Admin directly creates a TEACHER/STUDENT/PARENT account (auto-ACTIVE, no approval needed)
 *     tags: [Users]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [fullName, email, password, phoneNumber, role]
 *             properties:
 *               fullName: { type: string }
 *               email: { type: string, format: email }
 *               password: { type: string }
 *               phoneNumber: { type: string }
 *               role: { type: string, enum: [TEACHER, STUDENT, PARENT] }
 *               extraInfo: { type: string }
 *               joiningDate: { type: string, format: date }
 *               assignedSections: { type: array, items: { type: string } }
 *     responses:
 *       201:
 *         description: User created.
 *       409:
 *         description: Email already registered.
 */
usersRouter
  .route('/')
  .get(validate({ query: listUsersQuerySchema }), usersController.listByRole)
  .post(validate({ body: createUserByAdminSchema }), usersController.createByAdmin);

/**
 * @openapi
 * /users/{id}:
 *   get:
 *     summary: Get one user by id (must belong to the admin's academy)
 *     tags: [Users]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: User found. }
 *       404: { description: No such user in this academy. }
 *   patch:
 *     summary: Update a user's profile fields
 *     tags: [Users]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fullName: { type: string }
 *               phoneNumber: { type: string }
 *               extraInfo: { type: string }
 *               joiningDate: { type: string, format: date }
 *               assignedSections: { type: array, items: { type: string } }
 *     responses:
 *       200: { description: User updated. }
 *       404: { description: No such user in this academy. }
 *   delete:
 *     summary: Soft-delete a user and revoke all of their active sessions
 *     tags: [Users]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: User removed. }
 *       404: { description: No such user in this academy. }
 */
usersRouter
  .route('/:id')
  .get(validate({ params: idParamSchema }), usersController.getOne)
  .patch(validate({ params: idParamSchema, body: updateUserSchema }), usersController.update)
  .delete(validate({ params: idParamSchema }), usersController.remove);
