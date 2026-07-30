import { z } from 'zod';
import { paginationQuerySchema } from './common.validators';

export const notificationListQuerySchema = paginationQuerySchema.extend({
  unreadOnly: z.coerce.boolean().default(false),
});
