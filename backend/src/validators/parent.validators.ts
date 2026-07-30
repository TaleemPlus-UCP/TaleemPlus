import { z } from 'zod';
import { paginationQuerySchema } from './common.validators';

export const linkChildSchema = z
  .object({
    email: z.string().trim().toLowerCase().email().optional(),
    studentId: z.string().uuid().optional(),
  })
  .refine((data) => Boolean(data.email) !== Boolean(data.studentId), {
    message: 'Provide exactly one of email or studentId.',
  });

export const childIdParamSchema = z.object({
  childId: z.string().uuid('childId must be a valid UUID.'),
});

export const searchStudentsQuerySchema = paginationQuerySchema.extend({
  query: z.string().trim().min(1).max(100),
});
