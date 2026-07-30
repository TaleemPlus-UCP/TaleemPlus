import { Request } from 'express';
import { RequestMeta } from '../services/token.service';

/** Express is configured with `trust proxy` so this resolves the real client IP behind a reverse proxy too. */
export function getRequestMeta(req: Request): RequestMeta {
  return {
    ipAddress: req.ip,
    userAgent: req.headers['user-agent'],
  };
}
