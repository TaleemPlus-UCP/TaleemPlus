import { Router } from 'express';
import * as controller from '../controllers/academies.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { updateAcademySchema } from '../validators/academy.validators';

export const academiesRouter = Router();

academiesRouter.use(authenticate, requireActiveAccount, requireRoles('ADMIN'));

/**
 * @openapi
 * /academies/me:
 *   patch:
 *     summary: Update the caller's own academy branding (name/address/phone/logoUrl) — admin only
 *     tags: [Academies]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name: { type: string }
 *               address: { type: string }
 *               phone: { type: string }
 *               logoUrl: { type: string, format: uri }
 *     responses:
 *       200: { description: Academy updated. }
 *       422: { description: At least one field must be provided. }
 */
academiesRouter.patch('/me', validate({ body: updateAcademySchema }), controller.updateMine);
