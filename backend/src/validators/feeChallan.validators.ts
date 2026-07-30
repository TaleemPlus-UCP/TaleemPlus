import { z } from 'zod';
import { paginationQuerySchema } from './common.validators';

const currentYear = new Date().getFullYear();
const yearSchema = z.coerce.number().int().min(2000).max(currentYear + 1);
const monthSchema = z.coerce.number().int().min(1).max(12);
const moneySchema = z.coerce.number().min(0).max(10_000_000);

export const generateChallansSchema = z.object({
  sectionId: z.string().uuid(),
  billingYear: yearSchema,
  billingMonth: monthSchema,
  monthlyFee: moneySchema,
  admissionFee: moneySchema.default(0),
  examFee: moneySchema.default(0),
  transportFee: moneySchema.default(0),
  fine: moneySchema.default(0),
  dueDate: z.coerce.date().optional(),
});

/** For one ad-hoc challan aimed at a single student, e.g. a one-off library fine. */
export const createChallanSchema = z.object({
  studentId: z.string().uuid(),
  billingYear: yearSchema,
  billingMonth: monthSchema,
  monthlyFee: moneySchema,
  admissionFee: moneySchema.default(0),
  examFee: moneySchema.default(0),
  transportFee: moneySchema.default(0),
  fine: moneySchema.default(0),
  dueDate: z.coerce.date().optional(),
});

export const updateChallanStatusSchema = z.object({
  status: z.enum(['PENDING', 'PAID', 'OVERDUE']),
});

export const listChallansQuerySchema = paginationQuerySchema.extend({
  studentId: z.string().uuid().optional(),
  billingYear: yearSchema.optional(),
  billingMonth: monthSchema.optional(),
  status: z.enum(['PENDING', 'PAID', 'OVERDUE']).optional(),
});

export const sectionStatusQuerySchema = z.object({
  year: yearSchema.optional(),
  month: monthSchema.optional(),
});
