import { z } from 'zod';

export const analyzeTextSchema = z.object({
  text: z.string().min(1).max(50000),
});

export const generateQuestionsSchema = z.object({
  text: z.string().min(1).max(50000),
  mcqCount: z.coerce.number().int().min(0).max(50),
  shortCount: z.coerce.number().int().min(0).max(50),
  longCount: z.coerce.number().int().min(0).max(50),
});

export const summarizeTextSchema = z.object({
  text: z.string().min(1).max(50000),
});
