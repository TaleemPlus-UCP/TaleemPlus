const { validatePassword } = require('../src/utils/passwordPolicy');

describe('password policy', () => {
  test('requires at least eight characters', () => {
    expect(validatePassword('short7')).toMatch(/at least 8/i);
  });

  test('rejects common passwords and repeated characters', () => {
    expect(validatePassword('Password123')).toMatch(/less common/i);
    expect(validatePassword('aaaaaaaa')).toMatch(/less common/i);
  });

  test('accepts a sufficiently long non-common password', () => {
    expect(validatePassword('Academy!7Term')).toBeNull();
  });
});
