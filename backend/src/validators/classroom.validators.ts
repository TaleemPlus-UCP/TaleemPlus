import { z } from 'zod';

export const offeringQuerySchema = z.object({
  offeringId: z.string().uuid(),
});

export const createLearningResourceSchema = z.object({
  offeringId: z.string().uuid(),
  title: z.string().trim().min(1).max(200),
  description: z.string().trim().max(2000).optional(),
  linkUrl: z.string().trim().url().max(1000).optional(),
});

export const createStudentQuerySchema = z.object({
  offeringId: z.string().uuid(),
  question: z.string().trim().min(1).max(2000),
});

export const answerStudentQuerySchema = z.object({
  answer: z.string().trim().min(1).max(2000),
});
