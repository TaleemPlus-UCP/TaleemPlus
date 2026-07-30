import { z } from 'zod';
import { paginationQuerySchema } from './common.validators';

const questionSchema = z
  .object({
    text: z.string().trim().min(1).max(2000),
    type: z.enum(['MCQ', 'SHORT', 'LONG']),
    options: z.array(z.string().trim().min(1).max(300)).max(10).optional(),
    correctIndex: z.coerce.number().int().min(0).optional(),
    marks: z.coerce.number().positive().max(1000),
    gradingKeywords: z.array(z.string().trim().min(1).max(60)).max(30).default([]),
  })
  .superRefine((data, ctx) => {
    if (data.type === 'MCQ') {
      if (!data.options || data.options.length < 2) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'MCQ questions need at least 2 options.',
          path: ['options'],
        });
      }
      if (data.correctIndex === undefined || (data.options && data.correctIndex >= data.options.length)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'correctIndex is required for MCQ questions and must index into options.',
          path: ['correctIndex'],
        });
      }
    } else {
      if (data.options && data.options.length > 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Only MCQ questions may have options.',
          path: ['options'],
        });
      }
      if (data.correctIndex !== undefined) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Only MCQ questions may have a correctIndex.',
          path: ['correctIndex'],
        });
      }
    }
  });

export const createQuizSchema = z.object({
  offeringId: z.string().uuid(),
  title: z.string().trim().min(1).max(200),
  subject: z.string().trim().min(1).max(100),
  session: z.string().trim().max(100).optional(),
  chapter: z.string().trim().max(200).optional(),
  difficulty: z.enum(['EASY', 'MEDIUM', 'HARD']).default('MEDIUM'),
  totalMarks: z.coerce.number().positive().max(10000),
  testDate: z.coerce.date(),
  instructions: z.string().trim().max(2000).optional(),
  questions: z.array(questionSchema).min(1, 'A quiz needs at least one question.'),
});

export const updateQuizSchema = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    subject: z.string().trim().min(1).max(100).optional(),
    session: z.string().trim().max(100).nullable().optional(),
    chapter: z.string().trim().max(200).nullable().optional(),
    difficulty: z.enum(['EASY', 'MEDIUM', 'HARD']).optional(),
    totalMarks: z.coerce.number().positive().max(10000).optional(),
    testDate: z.coerce.date().optional(),
    instructions: z.string().trim().max(2000).nullable().optional(),
    questions: z.array(questionSchema).min(1).optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'At least one field must be provided.' });

export const listQuizzesQuerySchema = paginationQuerySchema.extend({
  offeringId: z.string().uuid().optional(),
});

export const gradeSuggestionSchema = z.object({
  ocrText: z.string().min(1).max(20000),
});

export const marksUpsertSchema = z.object({
  records: z
    .array(
      z.object({
        studentId: z.string().uuid(),
        marksObtained: z.coerce.number().min(0),
        teacherFeedback: z.string().trim().max(1000).optional(),
      }),
    )
    .min(1),
});

export const studentMarksQuerySchema = paginationQuerySchema.extend({
  subject: z.string().trim().optional(),
  year: z.coerce.number().int().min(2000).optional(),
  month: z.coerce.number().int().min(1).max(12).optional(),
});
