import crypto from 'crypto';

/**
 * Refresh tokens and password-reset tokens are only ever stored as this
 * hash — the raw value is sent to the client once and never persisted,
 * so a database leak alone cannot be replayed as a valid token.
 */
export function hashToken(rawToken: string): string {
  return crypto.createHash('sha256').update(rawToken).digest('hex');
}

export function generateRawToken(): string {
  return crypto.randomBytes(32).toString('hex');
}
