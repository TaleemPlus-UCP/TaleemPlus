import { z } from 'zod';

export const createOcrDocumentSchema = z.object({
  title: z.string().trim().min(1).max(200),
  extractedText: z.string().min(1).max(50000),
});

export const updateOcrDocumentSchema = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    extractedText: z.string().min(1).max(50000).optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'At least one field must be provided.' });
