import request from 'supertest';
import { createApp } from '../src/app';

const app = createApp();

const ADMIN_PAYLOAD = {
  fullName: 'Test Admin',
  email: 'admin@test.local',
  password: 'Passw0rd!',
  phoneNumber: '+920000000001',
  role: 'ADMIN' as const,
  academyName: 'Test Academy',
  academyAddress: '1 Test St',
  academyPhone: '+920000000000',
};

async function registerAdmin() {
  return request(app).post('/api/v1/auth/register').send(ADMIN_PAYLOAD);
}

describe('POST /api/v1/auth/register', () => {
  it('registers an ADMIN, auto-activates the account, creates an academy, and returns tokens', async () => {
    const res = await registerAdmin();

    expect(res.status).toBe(201);
    expect(res.body.data.user.role).toBe('ADMIN');
    expect(res.body.data.user.accountStatus).toBe('ACTIVE');
    expect(res.body.data.user.academy.code).toMatch(/^TP-/);
    expect(res.body.data.tokens.accessToken).toEqual(expect.any(String));
    expect(res.body.data.tokens.refreshToken).toEqual(expect.any(String));
  });

  it('rejects a second registration with the same email', async () => {
    await registerAdmin();
    const res = await registerAdmin();

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
  });

  it('rejects a non-admin registration with an invalid academy code', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Test Teacher',
        email: 'teacher@test.local',
        password: 'Passw0rd!',
        phoneNumber: '+920000000002',
        role: 'TEACHER',
        academyCode: 'TP-NOPE1',
      });

    expect(res.status).toBe(400);
  });

  it('registers a TEACHER as PENDING (no tokens) when joining via a valid academy code', async () => {
    const adminRes = await registerAdmin();
    const academyCode = adminRes.body.data.user.academy.code;

    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Test Teacher',
        email: 'teacher@test.local',
        password: 'Passw0rd!',
        phoneNumber: '+920000000002',
        role: 'TEACHER',
        academyCode,
      });

    expect(res.status).toBe(201);
    expect(res.body.data.user.accountStatus).toBe('PENDING');
    expect(res.body.data.tokens).toBeNull();
  });

  it('rejects weak passwords with a 422', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ ...ADMIN_PAYLOAD, password: 'weak' });

    expect(res.status).toBe(422);
  });
});

describe('POST /api/v1/auth/login', () => {
  it('logs in an ACTIVE user and returns a token pair', async () => {
    await registerAdmin();

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: ADMIN_PAYLOAD.email, password: ADMIN_PAYLOAD.password });

    expect(res.status).toBe(200);
    expect(res.body.data.tokens.accessToken).toEqual(expect.any(String));
  });

  it('returns a generic 401 for a wrong password (no user-enumeration leak)', async () => {
    await registerAdmin();

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: ADMIN_PAYLOAD.email, password: 'WrongPassword1' });

    expect(res.status).toBe(401);
    expect(res.body.message).toMatch(/invalid credentials/i);
  });

  it('returns the same generic 401 message for a non-existent email', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'nobody@test.local', password: 'WrongPassword1' });

    expect(res.status).toBe(401);
    expect(res.body.message).toMatch(/invalid credentials/i);
  });

  it('blocks a PENDING account with a 403', async () => {
    const adminRes = await registerAdmin();
    const academyCode = adminRes.body.data.user.academy.code;
    await request(app)
      .post('/api/v1/auth/register')
      .send({
        fullName: 'Test Teacher',
        email: 'teacher@test.local',
        password: 'Passw0rd!',
        phoneNumber: '+920000000002',
        role: 'TEACHER',
        academyCode,
      });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'teacher@test.local', password: 'Passw0rd!' });

    expect(res.status).toBe(403);
    expect(res.body.message).toMatch(/pending admin approval/i);
  });
});

describe('GET /api/v1/auth/me', () => {
  it('rejects requests with no Authorization header', async () => {
    const res = await request(app).get('/api/v1/auth/me');
    expect(res.status).toBe(401);
  });

  it('returns the current user profile for a valid access token', async () => {
    const registerRes = await registerAdmin();
    const { accessToken } = registerRes.body.data.tokens;

    const res = await request(app).get('/api/v1/auth/me').set('Authorization', `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.user.email).toBe(ADMIN_PAYLOAD.email);
  });

  it('rejects a malformed bearer token', async () => {
    const res = await request(app).get('/api/v1/auth/me').set('Authorization', 'Bearer not-a-real-token');
    expect(res.status).toBe(401);
  });
});

describe('POST /api/v1/auth/refresh', () => {
  it('rotates the refresh token and issues a new access token', async () => {
    const registerRes = await registerAdmin();
    const { refreshToken } = registerRes.body.data.tokens;

    const res = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });

    expect(res.status).toBe(200);
    expect(res.body.data.tokens.refreshToken).not.toBe(refreshToken);
  });

  it('detects refresh-token reuse and revokes every session for that user', async () => {
    const registerRes = await registerAdmin();
    const { refreshToken: firstRefresh } = registerRes.body.data.tokens;

    const rotated = await request(app).post('/api/v1/auth/refresh').send({ refreshToken: firstRefresh });
    const { refreshToken: secondRefresh } = rotated.body.data.tokens;

    // Reusing the already-rotated (now revoked) first token is a theft signal.
    const reuseAttempt = await request(app).post('/api/v1/auth/refresh').send({ refreshToken: firstRefresh });
    expect(reuseAttempt.status).toBe(401);

    // Every token for the user — including the legitimately-rotated second one — is now dead.
    const secondAttempt = await request(app).post('/api/v1/auth/refresh').send({ refreshToken: secondRefresh });
    expect(secondAttempt.status).toBe(401);
  });

  it('rejects an unknown refresh token', async () => {
    const res = await request(app).post('/api/v1/auth/refresh').send({ refreshToken: 'a'.repeat(64) });
    expect(res.status).toBe(401);
  });
});

describe('POST /api/v1/auth/logout', () => {
  it('revokes the given refresh token so it can no longer be used', async () => {
    const registerRes = await registerAdmin();
    const { accessToken, refreshToken } = registerRes.body.data.tokens;

    const logoutRes = await request(app)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ refreshToken });
    expect(logoutRes.status).toBe(200);

    const refreshRes = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });
    expect(refreshRes.status).toBe(401);
  });
});

describe('academy lookup', () => {
  it('finds an academy by its join code', async () => {
    const adminRes = await registerAdmin();
    const code = adminRes.body.data.user.academy.code;

    const res = await request(app).get(`/api/v1/auth/academy?code=${code}`);
    expect(res.status).toBe(200);
    expect(res.body.data.academy.name).toBe(ADMIN_PAYLOAD.academyName);
  });

  it('returns 404 for an unknown code', async () => {
    const res = await request(app).get('/api/v1/auth/academy?code=TP-NOPE1');
    expect(res.status).toBe(404);
  });
});

describe('forgot / reset password', () => {
  it('always returns 200 for forgot-password, even for an unregistered email', async () => {
    const res = await request(app).post('/api/v1/auth/forgot-password').send({ email: 'nobody@test.local' });
    expect(res.status).toBe(200);
  });

  it('rejects reset-password with an invalid token', async () => {
    const res = await request(app)
      .post('/api/v1/auth/reset-password')
      .send({ token: 'a'.repeat(64), newPassword: 'NewPassw0rd!' });
    expect(res.status).toBe(400);
  });
});

describe('security question recovery', () => {
  it('sets, looks up, verifies, and recovers via a security question', async () => {
    const registerRes = await registerAdmin();
    const { accessToken } = registerRes.body.data.tokens;

    const setRes = await request(app)
      .post('/api/v1/auth/security-question')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ question: 'What is your favorite color?', answer: 'Blue' });
    expect(setRes.status).toBe(200);

    const getRes = await request(app).get(`/api/v1/auth/security-question?email=${ADMIN_PAYLOAD.email}`);
    expect(getRes.status).toBe(200);
    expect(getRes.body.data.question).toBe('What is your favorite color?');

    const verifyWrong = await request(app)
      .post('/api/v1/auth/security-question/verify')
      .send({ email: ADMIN_PAYLOAD.email, answer: 'Red' });
    expect(verifyWrong.body.data.isCorrect).toBe(false);

    const verifyRight = await request(app)
      .post('/api/v1/auth/security-question/verify')
      .send({ email: ADMIN_PAYLOAD.email, answer: '  BLUE  ' }); // case/whitespace-insensitive
    expect(verifyRight.body.data.isCorrect).toBe(true);

    const recoverRes = await request(app)
      .post('/api/v1/auth/security-question/recover')
      .send({ email: ADMIN_PAYLOAD.email, answer: 'blue', newPassword: 'BrandNewPass1' });
    expect(recoverRes.status).toBe(200);

    const loginOld = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: ADMIN_PAYLOAD.email, password: ADMIN_PAYLOAD.password });
    expect(loginOld.status).toBe(401);

    const loginNew = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: ADMIN_PAYLOAD.email, password: 'BrandNewPass1' });
    expect(loginNew.status).toBe(200);
  });

  it('returns 404 when no security question is configured for the email', async () => {
    await registerAdmin();
    const res = await request(app).get(`/api/v1/auth/security-question?email=${ADMIN_PAYLOAD.email}`);
    expect(res.status).toBe(404);
  });
});

describe('POST /api/v1/auth/change-password', () => {
  it('rejects the wrong current password', async () => {
    const registerRes = await registerAdmin();
    const { accessToken } = registerRes.body.data.tokens;

    const res = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ currentPassword: 'WrongOne1', newPassword: 'BrandNewPass1' });
    expect(res.status).toBe(401);
  });

  it('changes the password and revokes every session, including the current one', async () => {
    const registerRes = await registerAdmin();
    const { accessToken, refreshToken } = registerRes.body.data.tokens;

    const res = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ currentPassword: ADMIN_PAYLOAD.password, newPassword: 'BrandNewPass1' });
    expect(res.status).toBe(200);

    const refreshAttempt = await request(app).post('/api/v1/auth/refresh').send({ refreshToken });
    expect(refreshAttempt.status).toBe(401);

    const loginOld = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: ADMIN_PAYLOAD.email, password: ADMIN_PAYLOAD.password });
    expect(loginOld.status).toBe(401);

    const loginNew = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: ADMIN_PAYLOAD.email, password: 'BrandNewPass1' });
    expect(loginNew.status).toBe(200);
  });
});

describe('POST /api/v1/auth/relink-academy', () => {
  it('rejects an invalid academy code', async () => {
    const registerRes = await registerAdmin();
    const { accessToken } = registerRes.body.data.tokens;

    const res = await request(app)
      .post('/api/v1/auth/relink-academy')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ code: 'TP-NOPE1' });
    expect(res.status).toBe(404);
  });

  it("relinks the caller's own account to a different academy by code", async () => {
    const otherAcademyRes = await request(app)
      .post('/api/v1/auth/register')
      .send({ ...ADMIN_PAYLOAD, email: 'other-admin@test.local', academyName: 'Other Academy' });
    const otherCode = otherAcademyRes.body.data.user.academy.code;

    const registerRes = await registerAdmin();
    const { accessToken } = registerRes.body.data.tokens;

    const res = await request(app)
      .post('/api/v1/auth/relink-academy')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ code: otherCode });
    expect(res.status).toBe(200);
    expect(res.body.data.user.academy.code).toBe(otherCode);
  });
});
