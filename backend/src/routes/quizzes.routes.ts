import { Router } from 'express';
import * as quizzesController from '../controllers/quizzes.controller';
import * as marksController from '../controllers/marks.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { idParamSchema } from '../validators/common.validators';
import {
  createQuizSchema,
  gradeSuggestionSchema,
  listQuizzesQuerySchema,
  marksUpsertSchema,
  updateQuizSchema,
} from '../validators/quiz.validators';
import { z } from 'zod';

export const quizzesRouter = Router();

// Quiz definitions carry the answer key — every route here is staff-only (ADMIN/TEACHER).
quizzesRouter.use(authenticate, requireActiveAccount, requireRoles('ADMIN', 'TEACHER'));

const questionParamSchema = z.object({ id: idParamSchema.shape.id, questionId: z.string().uuid() });
const quizIdParamSchema = z.object({ quizId: idParamSchema.shape.id });

/**
 * @openapi
 * /quizzes:
 *   get:
 *     summary: List quizzes (admin sees the academy, teacher sees only quizzes for offerings they teach) — staff only, answer keys included
 *     tags: [Quizzes]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: query
 *         name: offeringId
 *         schema: { type: string, format: uuid }
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200: { description: Paginated list, newest test date first. }
 *   post:
 *     summary: Create a quiz with its questions
 *     tags: [Quizzes]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [offeringId, title, subject, totalMarks, testDate, questions]
 *             properties:
 *               offeringId: { type: string, format: uuid }
 *               title: { type: string }
 *               subject: { type: string }
 *               session: { type: string }
 *               chapter: { type: string }
 *               difficulty: { type: string, enum: [EASY, MEDIUM, HARD] }
 *               totalMarks: { type: number }
 *               testDate: { type: string, format: date }
 *               instructions: { type: string }
 *               questions:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required: [text, type, marks]
 *                   properties:
 *                     text: { type: string }
 *                     type: { type: string, enum: [MCQ, SHORT, LONG] }
 *                     options: { type: array, items: { type: string } }
 *                     correctIndex: { type: integer }
 *                     marks: { type: number }
 *                     gradingKeywords: { type: array, items: { type: string } }
 *     responses:
 *       201: { description: Quiz created. }
 *       400: { description: offeringId does not belong to your academy. }
 *       422: { description: Validation failed (e.g. MCQ missing options/correctIndex). }
 */
quizzesRouter
  .route('/')
  .get(validate({ query: listQuizzesQuerySchema }), quizzesController.list)
  .post(validate({ body: createQuizSchema }), quizzesController.create);

/**
 * @openapi
 * /quizzes/{id}:
 *   get:
 *     summary: Get one quiz with its full question list (answer key included)
 *     tags: [Quizzes]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Quiz found. }
 *       404: { description: Quiz not found in your academy (or not one you teach). }
 *   patch:
 *     summary: Update quiz metadata and/or fully replace its question list
 *     tags: [Quizzes]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Quiz updated. }
 *       404: { description: Quiz not found in your academy. }
 *   delete:
 *     summary: Delete a quiz (cascades to its questions and any marks already entered)
 *     tags: [Quizzes]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Quiz deleted. }
 *       404: { description: Quiz not found in your academy. }
 */
quizzesRouter
  .route('/:id')
  .get(validate({ params: idParamSchema }), quizzesController.getOne)
  .patch(validate({ params: idParamSchema, body: updateQuizSchema }), quizzesController.update)
  .delete(validate({ params: idParamSchema }), quizzesController.remove);

/**
 * @openapi
 * /quizzes/{id}/questions/{questionId}/grade-suggestion:
 *   post:
 *     summary: AI Smart Grader — score a Short/Long answer against the question's teacher-authored grading keywords, given OCR'd answer text
 *     tags: [Quizzes]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string, format: uuid }
 *       - in: path
 *         name: questionId
 *         required: true
 *         schema: { type: string, format: uuid }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [ocrText]
 *             properties:
 *               ocrText: { type: string }
 *     responses:
 *       200: { description: "{ matches, keywordCount, matchedKeywords, suggestedMarks }" }
 *       400: { description: Question is an MCQ (not eligible for AI grading). }
 *       404: { description: Quiz or question not found. }
 */
quizzesRouter.post(
  '/:id/questions/:questionId/grade-suggestion',
  validate({ params: questionParamSchema, body: gradeSuggestionSchema }),
  quizzesController.gradeSuggestion,
);

/**
 * @openapi
 * /quizzes/{quizId}/marks:
 *   get:
 *     summary: List every mark entered for this quiz
 *     tags: [Marks]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: quizId
 *         required: true
 *         schema: { type: string, format: uuid }
 *     responses:
 *       200: { description: Marks for this quiz. }
 *       404: { description: Quiz not found in your academy. }
 *   put:
 *     summary: Upsert marks for one or more students on this quiz (percentage/grade computed server-side)
 *     tags: [Marks]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: quizId
 *         required: true
 *         schema: { type: string, format: uuid }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [records]
 *             properties:
 *               records:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required: [studentId, marksObtained]
 *                   properties:
 *                     studentId: { type: string, format: uuid }
 *                     marksObtained: { type: number }
 *                     teacherFeedback: { type: string }
 *     responses:
 *       200: { description: Marks saved; returns the full updated mark list for the quiz. }
 *       400: { description: One or more students are not enrolled in this class section. }
 *       404: { description: Quiz not found in your academy. }
 */
quizzesRouter
  .route('/:quizId/marks')
  .get(validate({ params: quizIdParamSchema }), marksController.listForQuiz)
  .put(validate({ params: quizIdParamSchema, body: marksUpsertSchema }), marksController.upsertMarks);
