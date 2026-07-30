import crypto from 'crypto';

const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I ambiguity

/** Generates a human-friendly join code in the legacy `TP-XXXXX` shape. */
export function generateAcademyCode(): string {
  let suffix = '';
  for (let i = 0; i < 5; i += 1) {
    suffix += CODE_ALPHABET[crypto.randomInt(CODE_ALPHABET.length)];
  }
  return `TP-${suffix}`;
}
