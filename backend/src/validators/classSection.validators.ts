import { z } from 'zod';

export const createSectionSchema = z.object({
  className: z.string().trim().min(1).max(60),
  sectionLabel: z.string().trim().min(1).max(20),
});

export const listSectionsQuerySchema = z.object({
  className: z.string().trim().max(60).optional(),
});

export const updateEnrollmentSchema = z.object({
  studentIds: z.array(z.string().uuid()).max(1000),
});
