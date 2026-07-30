import { z } from 'zod';
import { PAGINATION_DEFAULTS } from '../constants/roles';

export const paginationQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(PAGINATION_DEFAULTS.PAGE),
  limit: z.coerce.number().int().min(1).max(PAGINATION_DEFAULTS.MAX_LIMIT).default(PAGINATION_DEFAULTS.LIMIT),
});

export const idParamSchema = z.object({
  id: z.string().uuid('id must be a valid UUID.'),
});
