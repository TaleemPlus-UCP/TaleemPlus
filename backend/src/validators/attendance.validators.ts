import { z } from 'zod';

const ATTENDANCE_STATUSES = ['PRESENT', 'ABSENT', 'LATE'] as const;

export const markSheetSchema = z.object({
  offeringId: z.string().uuid(),
  logDate: z.coerce.date(),
  records: z
    .array(
      z.object({
        studentId: z.string().uuid(),
        status: z.enum(ATTENDANCE_STATUSES),
      }),
    )
    .min(1, 'At least one student record is required.'),
});

export const daySheetQuerySchema = z.object({
  offeringId: z.string().uuid(),
  logDate: z.coerce.date(),
});

const currentYear = new Date().getFullYear();

export const monthlyQuerySchema = z.object({
  year: z.coerce.number().int().min(2000).max(currentYear + 1).optional(),
  month: z.coerce.number().int().min(1).max(12).optional(),
});

export const yearlyQuerySchema = z.object({
  year: z.coerce.number().int().min(2000).max(currentYear + 1).optional(),
});
