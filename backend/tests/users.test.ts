import request from 'supertest';
import { createApp } from '../src/app';

const app = createApp();

async function registerAdmin(suffix: string) {
  const res = await request(app)
    .post('/api/v1/auth/register')
    .send({
      fullName: `Admin ${suffix}`,
      email: `admin-${suffix}@test.local`,
      password: 'Passw0rd!',
      phoneNumber: '+920000001000',
      role: 'ADMIN',
      academyName: `Academy ${suffix}`,
    });
  return {
    accessToken: res.body.data.tokens.accessToken as string,
    academyCode: res.body.data.user.academy.code as string,
    userId: res.body.data.user.id as string,
  };
}

async function registerTeacher(academyCode: string, suffix: string) {
  const res = await request(app)
    .post('/api/v1/auth/register')
    .send({
      fullName: `Teacher ${suffix}`,
      email: `teacher-${suffix}@test.local`,
      password: 'Passw0rd!',
      phoneNumber: '+920000002000',
      role: 'TEACHER',
      academyCode,
    });
  return { userId: res.body.data.user.id as string, email: `teacher-${suffix}@test.local` };
}

describe('GET /api/v1/users/pending', () => {
  it('rejects unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/users/pending');
    expect(res.status).toBe(401);
  });

  it('lists PENDING users scoped to the admin academy', async () => {
    const admin = await registerAdmin('p1');
    await registerTeacher(admin.academyCode, 'p1');

    const res = await request(app)
      .get('/api/v1/users/pending')
      .set('Authorization', `Bearer ${admin.accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].accountStatus).toBe('PENDING');
    expect(res.body.meta.total).toBe(1);
  });

  it('rejects a non-admin caller with 403', async () => {
    const admin = await registerAdmin('p2');
    const teacher = await registerTeacher(admin.academyCode, 'p2');
    await request(app)
      .post(`/api/v1/users/${teacher.userId}/approve`)
      .set('Authorization', `Bearer ${admin.accessToken}`);

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: teacher.email, password: 'Passw0rd!' });

    const res = await request(app)
      .get('/api/v1/users/pending')
      .set('Authorization', `Bearer ${loginRes.body.data.tokens.accessToken}`);
    expect(res.status).toBe(403);
  });
});

describe('POST /api/v1/users/:id/approve and /reject', () => {
  it('approves a pending user, who can then log in', async () => {
    const admin = await registerAdmin('a1');
    const teacher = await registerTeacher(admin.academyCode, 'a1');

    const approveRes = await request(app)
      .post(`/api/v1/users/${teacher.userId}/approve`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(approveRes.status).toBe(200);
    expect(approveRes.body.data.accountStatus).toBe('ACTIVE');

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: teacher.email, password: 'Passw0rd!' });
    expect(loginRes.status).toBe(200);
  });

  it('rejects a pending user, who then cannot log in', async () => {
    const admin = await registerAdmin('r1');
    const teacher = await registerTeacher(admin.academyCode, 'r1');

    const rejectRes = await request(app)
      .post(`/api/v1/users/${teacher.userId}/reject`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(rejectRes.status).toBe(200);
    expect(rejectRes.body.data.accountStatus).toBe('REJECTED');

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: teacher.email, password: 'Passw0rd!' });
    expect(loginRes.status).toBe(403);
  });

  it('returns 400 when approving a user who is already ACTIVE', async () => {
    const admin = await registerAdmin('a2');
    const teacher = await registerTeacher(admin.academyCode, 'a2');
    await request(app)
      .post(`/api/v1/users/${teacher.userId}/approve`)
      .set('Authorization', `Bearer ${admin.accessToken}`);

    const secondApprove = await request(app)
      .post(`/api/v1/users/${teacher.userId}/approve`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(secondApprove.status).toBe(400);
  });

  it("returns 404 when an admin targets a user outside their own academy", async () => {
    const adminA = await registerAdmin('iso1');
    const adminB = await registerAdmin('iso2');
    const teacherOfA = await registerTeacher(adminA.academyCode, 'iso1');

    const res = await request(app)
      .post(`/api/v1/users/${teacherOfA.userId}/approve`)
      .set('Authorization', `Bearer ${adminB.accessToken}`);
    expect(res.status).toBe(404);
  });
});

describe('GET/POST /api/v1/users', () => {
  it('lists users of a role within the academy with pagination meta', async () => {
    const admin = await registerAdmin('list1');
    const teacher = await registerTeacher(admin.academyCode, 'list1');
    await request(app)
      .post(`/api/v1/users/${teacher.userId}/approve`)
      .set('Authorization', `Bearer ${admin.accessToken}`);

    const res = await request(app)
      .get('/api/v1/users?role=TEACHER')
      .set('Authorization', `Bearer ${admin.accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.meta).toEqual({ page: 1, limit: 20, total: 1, totalPages: 1 });
  });

  it('requires the role query param', async () => {
    const admin = await registerAdmin('list2');
    const res = await request(app).get('/api/v1/users').set('Authorization', `Bearer ${admin.accessToken}`);
    expect(res.status).toBe(422);
  });

  it('creates a STUDENT directly as ACTIVE, no approval needed', async () => {
    const admin = await registerAdmin('create1');

    const res = await request(app)
      .post('/api/v1/users')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        fullName: 'Direct Student',
        email: 'direct-student@test.local',
        password: 'Passw0rd!',
        phoneNumber: '+920000003000',
        role: 'STUDENT',
        extraInfo: 'Roll No. 5',
      });

    expect(res.status).toBe(201);
    expect(res.body.data.accountStatus).toBe('ACTIVE');
    expect(res.body.data.role).toBe('STUDENT');

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'direct-student@test.local', password: 'Passw0rd!' });
    expect(loginRes.status).toBe(200);
  });

  it('rejects creating a user with a duplicate email with 409', async () => {
    const admin = await registerAdmin('create2');
    const payload = {
      fullName: 'Dup Student',
      email: 'dup-student@test.local',
      password: 'Passw0rd!',
      phoneNumber: '+920000004000',
      role: 'STUDENT' as const,
    };
    await request(app).post('/api/v1/users').set('Authorization', `Bearer ${admin.accessToken}`).send(payload);
    const res = await request(app)
      .post('/api/v1/users')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send(payload);
    expect(res.status).toBe(409);
  });
});

describe('GET/PATCH/DELETE /api/v1/users/:id', () => {
  it('gets, updates, and soft-deletes a user, revoking their sessions', async () => {
    const admin = await registerAdmin('crud1');
    const createRes = await request(app)
      .post('/api/v1/users')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        fullName: 'CRUD Student',
        email: 'crud-student@test.local',
        password: 'Passw0rd!',
        phoneNumber: '+920000005000',
        role: 'STUDENT',
      });
    const studentId = createRes.body.data.id;

    const getRes = await request(app)
      .get(`/api/v1/users/${studentId}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(getRes.status).toBe(200);

    const patchRes = await request(app)
      .patch(`/api/v1/users/${studentId}`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ fullName: 'Updated Name' });
    expect(patchRes.status).toBe(200);
    expect(patchRes.body.data.fullName).toBe('Updated Name');

    const deleteRes = await request(app)
      .delete(`/api/v1/users/${studentId}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(deleteRes.status).toBe(200);

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'crud-student@test.local', password: 'Passw0rd!' });
    expect(loginRes.status).toBe(401); // soft-deleted users are excluded from findByEmail
  });

  it('returns 422 when PATCH body is empty', async () => {
    const admin = await registerAdmin('crud2');
    const createRes = await request(app)
      .post('/api/v1/users')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        fullName: 'Empty Patch Student',
        email: 'empty-patch@test.local',
        password: 'Passw0rd!',
        phoneNumber: '+920000006000',
        role: 'STUDENT',
      });

    const res = await request(app)
      .patch(`/api/v1/users/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({});
    expect(res.status).toBe(422);
  });

  it('returns 404 for a user id outside the admin academy', async () => {
    const adminA = await registerAdmin('crud-iso1');
    const adminB = await registerAdmin('crud-iso2');
    const createRes = await request(app)
      .post('/api/v1/users')
      .set('Authorization', `Bearer ${adminA.accessToken}`)
      .send({
        fullName: 'Isolated Student',
        email: 'isolated-student@test.local',
        password: 'Passw0rd!',
        phoneNumber: '+920000007000',
        role: 'STUDENT',
      });

    const res = await request(app)
      .get(`/api/v1/users/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${adminB.accessToken}`);
    expect(res.status).toBe(404);
  });
});
