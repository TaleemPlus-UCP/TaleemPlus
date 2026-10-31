const COMMON_PASSWORDS = new Set([
  'password', 'password1', 'password123', '12345678', '123456789',
  'qwerty123', 'admin123', 'letmein', 'welcome1', 'iloveyou',
]);

function validatePassword(password) {
  if (typeof password !== 'string' || password.length < 8) {
    return 'Password must be at least 8 characters.';
  }
  const normalized = password.toLowerCase();
  if (COMMON_PASSWORDS.has(normalized) || /^(.)\1+$/.test(normalized) ||
      ['12345678', 'abcdefgh', 'qwertyui'].includes(normalized)) {
    return 'Choose a less common password.';
  }
  return null;
}

module.exports = { validatePassword };
