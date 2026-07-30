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
  };
}

async function registerPendingTeacher(academyCode: string, suffix: string) {
  const email = `teacher-${suffix}@test.local`;
  const res = await request(app)
    .post('/api/v1/auth/register')
    .send({
      fullName: `Teacher ${suffix}`,
      email,
      password: 'Passw0rd!',
      phoneNumber: '+920000002000',
      role: 'TEACHER',
      academyCode,
    });
  return { id: res.body.data.user.id as string, email };
}

describe('GET /api/v1/notifications', () => {
  it('rejects unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/notifications');
    expect(res.status).toBe(401);
  });

  it('starts empty for a fresh account', async () => {
    const admin = await registerAdmin('empty1');
    const res = await request(app).get('/api/v1/notifications').set('Authorization', `Bearer ${admin.accessToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toEqual([]);
    expect(res.body.meta.total).toBe(0);
  });
});

describe('approving/rejecting a user creates a notification (Module 2 retrofit)', () => {
  it('notifies the user on approval', async () => {
    const admin = await registerAdmin('approve1');
    const teacher = await registerPendingTeacher(admin.academyCode, 'approve1');

    await request(app)
      .post(`/api/v1/users/${teacher.id}/approve`)
      .set('Authorization', `Bearer ${admin.accessToken}`);

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: teacher.email, password: 'Passw0rd!' });

    const notifRes = await request(app)
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${loginRes.body.data.tokens.accessToken}`);
    expect(notifRes.body.data).toHaveLength(1);
    expect(notifRes.body.data[0].type).toBe('APPROVAL');
    expect(notifRes.body.data[0].title).toMatch(/approved/i);
  });
});

describe('unread count / mark read / mark all read', () => {
  it('tracks unread count and lets a user mark their own notifications read', async () => {
    const admin = await registerAdmin('mark1');
    await request(app)
      .post('/api/v1/users')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        fullName: 'Teacher mark1',
        email: 'teacher-mark1@test.local',
        password: 'Passw0rd!',
        phoneNumber: '+920000002000',
        role: 'TEACHER',
      });
    const teacherLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'teacher-mark1@test.local', password: 'Passw0rd!' });
    const teacherToken = teacherLogin.body.data.tokens.accessToken;

    await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'One', message: 'msg', isForAll: false, targetRoles: ['TEACHER'] });
    await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'Two', message: 'msg', isForAll: false, targetRoles: ['TEACHER'] });

    const unreadBefore = await request(app)
      .get('/api/v1/notifications/unread-count')
      .set('Authorization', `Bearer ${teacherToken}`);
    expect(unreadBefore.body.data.count).toBe(2);

    const list = await request(app).get('/api/v1/notifications').set('Authorization', `Bearer ${teacherToken}`);
    const firstId = list.body.data[0].id;

    const markOneRes = await request(app)
      .patch(`/api/v1/notifications/${firstId}/read`)
      .set('Authorization', `Bearer ${teacherToken}`);
    expect(markOneRes.status).toBe(200);
    expect(markOneRes.body.data.isRead).toBe(true);

    const unreadAfterOne = await request(app)
      .get('/api/v1/notifications/unread-count')
      .set('Authorization', `Bearer ${teacherToken}`);
    expect(unreadAfterOne.body.data.count).toBe(1);

    const markAllRes = await request(app)
      .post('/api/v1/notifications/mark-all-read')
      .set('Authorization', `Bearer ${teacherToken}`);
    expect(markAllRes.status).toBe(200);

    const unreadAfterAll = await request(app)
      .get('/api/v1/notifications/unread-count')
      .set('Authorization', `Bearer ${teacherToken}`);
    expect(unreadAfterAll.body.data.count).toBe(0);
  });

  it("returns 404 when trying to mark someone else's notification as read", async () => {
    const admin = await registerAdmin('mark2');
    await request(app)
      .post('/api/v1/users')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        fullName: 'Teacher mark2a',
        email: 'teacher-mark2a@test.local',
        password: 'Passw0rd!',
        phoneNumber: '+920000002000',
        role: 'TEACHER',
      });
    await request(app)
      .post('/api/v1/users')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        fullName: 'Teacher mark2b',
        email: 'teacher-mark2b@test.local',
        password: 'Passw0rd!',
        phoneNumber: '+920000002001',
        role: 'TEACHER',
      });

    await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'For teachers', message: 'msg', isForAll: false, targetRoles: ['TEACHER'] });

    const teacher1LoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'teacher-mark2a@test.local', password: 'Passw0rd!' });
    const teacher2LoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'teacher-mark2b@test.local', password: 'Passw0rd!' });

    const teacher1Notifs = await request(app)
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${teacher1LoginRes.body.data.tokens.accessToken}`);
    const notifId = teacher1Notifs.body.data[0].id;

    const res = await request(app)
      .patch(`/api/v1/notifications/${notifId}/read`)
      .set('Authorization', `Bearer ${teacher2LoginRes.body.data.tokens.accessToken}`);
    expect(res.status).toBe(404);
  });
});
