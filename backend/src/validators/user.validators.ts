import { z } from 'zod';
import { paginationQuerySchema } from './common.validators';

/** Admins never directly create/list other ADMIN accounts through this module — only via /auth/register. */
const MANAGEABLE_ROLES = ['TEACHER', 'STUDENT', 'PARENT'] as const;

export const listUsersQuerySchema = paginationQuerySchema.extend({
  role: z.enum(MANAGEABLE_ROLES),
  search: z.string().trim().max(120).optional(),
});

export const pendingUsersQuerySchema = paginationQuerySchema.extend({
  role: z.enum(MANAGEABLE_ROLES).optional(),
});

export const createUserByAdminSchema = z.object({
  fullName: z.string().trim().min(2).max(120),
  email: z.string().trim().toLowerCase().email('Enter a valid email address.'),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters.')
    .regex(/(?=.*[a-z])/, 'Password must contain a lowercase letter.')
    .regex(/(?=.*[A-Z])/, 'Password must contain an uppercase letter.')
    .regex(/(?=.*\d)/, 'Password must contain a digit.'),
  phoneNumber: z.string().trim().min(7).max(20),
  role: z.enum(MANAGEABLE_ROLES),
  extraInfo: z.string().trim().max(200).optional(),
  joiningDate: z.coerce.date().optional(),
  assignedSections: z.array(z.string().trim().min(1).max(10)).max(20).optional(),
});

export const updateUserSchema = z
  .object({
    fullName: z.string().trim().min(2).max(120).optional(),
    phoneNumber: z.string().trim().min(7).max(20).optional(),
    extraInfo: z.string().trim().max(200).optional(),
    joiningDate: z.coerce.date().optional(),
    assignedSections: z.array(z.string().trim().min(1).max(10)).max(20).optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'At least one field must be provided.' });
