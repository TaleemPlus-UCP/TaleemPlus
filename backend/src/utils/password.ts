import bcrypt from 'bcrypt';

const SALT_ROUNDS = 12;

export async function hashPassword(plainPassword: string): Promise<string> {
  return bcrypt.hash(plainPassword, SALT_ROUNDS);
}

export async function comparePassword(plainPassword: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plainPassword, hash);
}

const PASSWORD_MIN_LENGTH = 8;
const PASSWORD_STRENGTH_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/;

/** At least 8 chars, one lowercase, one uppercase, one digit. */
export function isStrongPassword(password: string): boolean {
  return password.length >= PASSWORD_MIN_LENGTH && PASSWORD_STRENGTH_REGEX.test(password);
}
