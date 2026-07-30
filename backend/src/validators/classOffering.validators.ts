import { z } from 'zod';

export const createOfferingSchema = z.object({
  sectionId: z.string().uuid(),
  teacherId: z.string().uuid(),
  subject: z.string().trim().max(100).optional().default(''),
});

export const updateOfferingSchema = z
  .object({
    subject: z.string().trim().max(100).optional(),
    teacherId: z.string().uuid().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'At least one field must be provided.' });

export const listOfferingsQuerySchema = z.object({
  sectionId: z.string().uuid().optional(),
});
