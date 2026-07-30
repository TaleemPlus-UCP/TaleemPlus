import { z } from 'zod';
import { paginationQuerySchema } from './common.validators';

const TARGET_ROLES = ['TEACHER', 'STUDENT', 'PARENT'] as const;

export const createAnnouncementSchema = z
  .object({
    title: z.string().trim().min(1).max(200),
    message: z.string().trim().min(1).max(5000),
    isForAll: z.boolean().default(false),
    targetRoles: z.array(z.enum(TARGET_ROLES)).default([]),
  })
  .refine((data) => data.isForAll || data.targetRoles.length > 0, {
    message: 'targetRoles must include at least one role unless isForAll is true.',
    path: ['targetRoles'],
  });

export const updateAnnouncementSchema = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    message: z.string().trim().min(1).max(5000).optional(),
    isForAll: z.boolean().optional(),
    targetRoles: z.array(z.enum(TARGET_ROLES)).optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'At least one field must be provided.' });

export const announcementListQuerySchema = paginationQuerySchema;
