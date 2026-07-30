import { z } from 'zod';
import { ROLES } from '../constants/roles';

const emailSchema = z.string().trim().toLowerCase().email('Enter a valid email address.');
const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters.')
  .regex(/(?=.*[a-z])/, 'Password must contain a lowercase letter.')
  .regex(/(?=.*[A-Z])/, 'Password must contain an uppercase letter.')
  .regex(/(?=.*\d)/, 'Password must contain a digit.');

export const registerSchema = z
  .object({
    fullName: z.string().trim().min(2, 'Full name is required.').max(120),
    email: emailSchema,
    password: passwordSchema,
    phoneNumber: z.string().trim().min(7).max(20),
    role: z.enum(ROLES),
    academyName: z.string().trim().min(2).max(150).optional(),
    academyAddress: z.string().trim().max(250).optional(),
    academyPhone: z.string().trim().max(20).optional(),
    academyCode: z.string().trim().toUpperCase().optional(),
    securityQuestion: z.string().trim().min(5).max(200).optional(),
    securityAnswer: z.string().trim().min(1).max(200).optional(),
  })
  .superRefine((data, ctx) => {
    if (data.role === 'ADMIN' && !data.academyName) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'academyName is required when registering as ADMIN.',
        path: ['academyName'],
      });
    }
    if (data.role !== 'ADMIN' && !data.academyCode) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'academyCode is required when joining as TEACHER, STUDENT, or PARENT.',
        path: ['academyCode'],
      });
    }
    if ((data.securityQuestion && !data.securityAnswer) || (!data.securityQuestion && data.securityAnswer)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'securityQuestion and securityAnswer must be provided together.',
        path: ['securityAnswer'],
      });
    }
  });

export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'Password is required.'),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(10, 'refreshToken is required.'),
});

export const academyLookupSchema = z.object({
  code: z.string().trim().toUpperCase().min(3),
});

export const forgotPasswordSchema = z.object({
  email: emailSchema,
});

export const resetPasswordSchema = z.object({
  token: z.string().min(10, 'token is required.'),
  newPassword: passwordSchema,
});

export const securityQuestionLookupSchema = z.object({
  email: emailSchema,
});

export const verifySecurityAnswerSchema = z.object({
  email: emailSchema,
  answer: z.string().min(1, 'answer is required.'),
});

export const recoverViaSecurityAnswerSchema = z.object({
  email: emailSchema,
  answer: z.string().min(1, 'answer is required.'),
  newPassword: passwordSchema,
});

export const setSecurityQuestionSchema = z.object({
  question: z.string().trim().min(5).max(200),
  answer: z.string().trim().min(1).max(200),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'currentPassword is required.'),
  newPassword: passwordSchema,
});

export const relinkAcademySchema = z.object({
  code: z.string().trim().toUpperCase().min(3),
});
