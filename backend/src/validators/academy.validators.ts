import { z } from 'zod';

export const updateAcademySchema = z
  .object({
    name: z.string().trim().min(1).max(200).optional(),
    address: z.string().trim().max(300).optional(),
    phone: z.string().trim().max(30).optional(),
    logoUrl: z.string().trim().url().max(500).optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'At least one field must be provided.' });
