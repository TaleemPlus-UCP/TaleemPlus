import { z } from 'zod';

const MINUTES_MAX = 24 * 60 - 1;

export const createSlotSchema = z
  .object({
    isBreak: z.boolean().default(false),
    offeringId: z.string().uuid().optional(),
    dayOfWeek: z.coerce.number().int().min(1).max(7),
    startMinutes: z.coerce.number().int().min(0).max(MINUTES_MAX),
    endMinutes: z.coerce.number().int().min(0).max(MINUTES_MAX),
    room: z.string().trim().max(50).optional(),
    semester: z.string().trim().max(50).optional(),
    effectiveFrom: z.coerce.date(),
    effectiveTo: z.coerce.date().optional(),
  })
  .superRefine((data, ctx) => {
    if (data.endMinutes <= data.startMinutes) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'endMinutes must be after startMinutes.',
        path: ['endMinutes'],
      });
    }
    if (data.isBreak && data.offeringId) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'A break slot cannot reference a class offering.',
        path: ['offeringId'],
      });
    }
    if (!data.isBreak && !data.offeringId) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'offeringId is required unless isBreak is true.',
        path: ['offeringId'],
      });
    }
    if (data.effectiveTo && data.effectiveTo < data.effectiveFrom) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'effectiveTo cannot be before effectiveFrom.',
        path: ['effectiveTo'],
      });
    }
  });

export const updateSlotSchema = z
  .object({
    isBreak: z.boolean().optional(),
    offeringId: z.string().uuid().nullable().optional(),
    dayOfWeek: z.coerce.number().int().min(1).max(7).optional(),
    startMinutes: z.coerce.number().int().min(0).max(MINUTES_MAX).optional(),
    endMinutes: z.coerce.number().int().min(0).max(MINUTES_MAX).optional(),
    room: z.string().trim().max(50).nullable().optional(),
    semester: z.string().trim().max(50).nullable().optional(),
    effectiveFrom: z.coerce.date().optional(),
    effectiveTo: z.coerce.date().nullable().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'At least one field must be provided.' })
  .refine((data) => data.startMinutes === undefined || data.endMinutes === undefined || data.endMinutes > data.startMinutes, {
    message: 'endMinutes must be after startMinutes.',
    path: ['endMinutes'],
  });

export const listSlotsQuerySchema = z.object({
  dayOfWeek: z.coerce.number().int().min(1).max(7).optional(),
  studentId: z.string().uuid().optional(),
});
