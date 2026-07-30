import { Router } from 'express';
import * as controller from '../controllers/studentQueries.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import { answerStudentQuerySchema, createStudentQuerySchema, offeringQuerySchema } from '../validators/classroom.validators';

export const studentQueriesRouter = Router();

studentQueriesRouter.use(authenticate, requireActiveAccount);

/**
 * @openapi
 * /student-queries:
 *   get:
 *     summary: List every question (and answer) posted to a class offering — a shared discussion wall, not scoped to the asker
 *     tags: [Classroom]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: offeringId
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Questions, newest first. }
 *   post:
 *     summary: Post a question to a class offering (student only)
 *     tags: [Classroom]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [offeringId, question]
 *             properties:
 *               offeringId: { type: string, format: uuid }
 *               question: { type: string }
 *     responses:
 *       201: { description: Question posted. }
 */
studentQueriesRouter
  .route('/')
  .get(validate({ query: offeringQuerySchema }), controller.list)
  .post(validate({ body: createStudentQuerySchema }), controller.create);

/**
 * @openapi
 * /student-queries/{id}:
 *   patch:
 *     summary: Answer a question (the class's teacher, or admin)
 *     tags: [Classroom]
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
 *             required: [answer]
 *             properties:
 *               answer: { type: string }
 *     responses:
 *       200: { description: Question answered. }
 *       404: { description: Question not found in your academy. }
 */
studentQueriesRouter.patch('/:id', validate({ params: idParamSchema, body: answerStudentQuerySchema }), controller.answer);
