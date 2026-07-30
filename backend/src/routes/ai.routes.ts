import { Router } from 'express';
import * as controller from '../controllers/ai.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';
import { validate } from '../middlewares/validate';
import { analyzeTextSchema, generateQuestionsSchema, summarizeTextSchema } from '../validators/ai.validators';

export const aiRouter = Router();

aiRouter.use(authenticate, requireActiveAccount);

/**
 * @openapi
 * /ai/test-generator/analyze:
 *   post:
 *     summary: AI Test Generator step 1 — estimate difficulty and a suggested MCQ/Short/Long question-count breakdown from OCR'd source text (admin/teacher only)
 *     tags: [AI]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [text]
 *             properties:
 *               text: { type: string }
 *     responses:
 *       200: { description: "{ difficulty, mcqCount, shortCount, longCount, preview }" }
 */
aiRouter.post(
  '/test-generator/analyze',
  requireRoles('ADMIN', 'TEACHER'),
  validate({ body: analyzeTextSchema }),
  controller.analyzeTestContent,
);

/**
 * @openapi
 * /ai/test-generator/generate:
 *   post:
 *     summary: AI Test Generator step 2 — generate draft MCQ/Short/Long questions from OCR'd source text (admin/teacher only); output feeds directly into POST /quizzes
 *     tags: [AI]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [text, mcqCount, shortCount, longCount]
 *             properties:
 *               text: { type: string }
 *               mcqCount: { type: integer }
 *               shortCount: { type: integer }
 *               longCount: { type: integer }
 *     responses:
 *       200: { description: "{ questions: [...] } — ready to merge into a quiz's questions array" }
 */
aiRouter.post(
  '/test-generator/generate',
  requireRoles('ADMIN', 'TEACHER'),
  validate({ body: generateQuestionsSchema }),
  controller.generateQuestions,
);

/**
 * @openapi
 * /ai/notes-summarizer:
 *   post:
 *     summary: AI Notes Summarizer — extractive line-classification of OCR'd notes into definitions and key points (any active role)
 *     tags: [AI]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [text]
 *             properties:
 *               text: { type: string }
 *     responses:
 *       200: { description: "{ definitions: string[], keyPoints: string[], isTooShort: boolean }" }
 */
aiRouter.post('/notes-summarizer', validate({ body: summarizeTextSchema }), controller.summarizeText);
