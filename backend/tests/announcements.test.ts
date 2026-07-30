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
  return { accessToken: res.body.data.tokens.accessToken as string };
}

async function createActiveUser(adminToken: string, role: 'TEACHER' | 'STUDENT' | 'PARENT', suffix: string) {
  const email = `${role.toLowerCase()}-${suffix}@test.local`;
  const createRes = await request(app)
    .post('/api/v1/users')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({
      fullName: `${role} ${suffix}`,
      email,
      password: 'Passw0rd!',
      phoneNumber: '+920000002000',
      role,
    });
  const login = await request(app).post('/api/v1/auth/login').send({ email, password: 'Passw0rd!' });
  return { id: createRes.body.data.id as string, accessToken: login.body.data.tokens.accessToken as string };
}

describe('POST /api/v1/announcements', () => {
  it('rejects unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/announcements');
    expect(res.status).toBe(401);
  });

  it('rejects a student trying to post an announcement', async () => {
    const admin = await registerAdmin('perm1');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'perm1');
    const res = await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${student.accessToken}`)
      .send({ title: 'Hi', message: 'Hello', isForAll: true });
    expect(res.status).toBe(403);
  });

  it('rejects isForAll=false with empty targetRoles', async () => {
    const admin = await registerAdmin('val1');
    const res = await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'Hi', message: 'Hello', isForAll: false, targetRoles: [] });
    expect(res.status).toBe(422);
  });

  it('lets a teacher post too, and excludes the creator from notification fan-out', async () => {
    const admin = await registerAdmin('create1');
    const teacher1 = await createActiveUser(admin.accessToken, 'TEACHER', 'create1a');
    const teacher2 = await createActiveUser(admin.accessToken, 'TEACHER', 'create1b');

    const res = await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${teacher1.accessToken}`)
      .send({ title: 'Staff meeting', message: 'Tomorrow 9am', isForAll: false, targetRoles: ['TEACHER'] });
    expect(res.status).toBe(201);

    const creatorNotifs = await request(app)
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${teacher1.accessToken}`);
    expect(creatorNotifs.body.data).toHaveLength(0);

    const otherTeacherNotifs = await request(app)
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${teacher2.accessToken}`);
    expect(otherTeacherNotifs.body.data).toHaveLength(1);
    expect(otherTeacherNotifs.body.data[0].type).toBe('ANNOUNCEMENT');
  });

  it('notifies only the targeted role, not others', async () => {
    const admin = await registerAdmin('target1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'target1');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'target1');

    await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'Teachers only', message: 'msg', isForAll: false, targetRoles: ['TEACHER'] });

    const teacherNotifs = await request(app)
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${teacher.accessToken}`);
    expect(teacherNotifs.body.data).toHaveLength(1);

    const studentNotifs = await request(app)
      .get('/api/v1/notifications')
      .set('Authorization', `Bearer ${student.accessToken}`);
    expect(studentNotifs.body.data).toHaveLength(0);
  });

  it('isForAll notifies every active role', async () => {
    const admin = await registerAdmin('all1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'all1');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'all1');
    const parent = await createActiveUser(admin.accessToken, 'PARENT', 'all1');

    await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'Holiday', message: 'School closed Monday', isForAll: true });

    for (const user of [teacher, student, parent]) {
      const res = await request(app).get('/api/v1/notifications').set('Authorization', `Bearer ${user.accessToken}`);
      expect(res.body.data).toHaveLength(1);
    }
  });
});

describe('GET /api/v1/announcements role scoping', () => {
  it('shows admins everything, and other roles only what targets them', async () => {
    const admin = await registerAdmin('scope1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'scope1');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'scope1');

    await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'Teachers only', message: 'msg', isForAll: false, targetRoles: ['TEACHER'] });
    await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'Everyone', message: 'msg', isForAll: true });

    const adminList = await request(app).get('/api/v1/announcements').set('Authorization', `Bearer ${admin.accessToken}`);
    expect(adminList.body.data).toHaveLength(2);

    const teacherList = await request(app)
      .get('/api/v1/announcements')
      .set('Authorization', `Bearer ${teacher.accessToken}`);
    expect(teacherList.body.data).toHaveLength(2); // "Teachers only" + "Everyone"

    const studentList = await request(app)
      .get('/api/v1/announcements')
      .set('Authorization', `Bearer ${student.accessToken}`);
    expect(studentList.body.data).toHaveLength(1); // only "Everyone"
  });
});

describe('PATCH/DELETE /api/v1/announcements/:id', () => {
  it('updates and deletes an announcement', async () => {
    const admin = await registerAdmin('crud1');
    const createRes = await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'Original', message: 'msg', isForAll: true });

    const patchRes = await request(app)
      .patch(`/api/v1/announcements/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'Updated title' });
    expect(patchRes.status).toBe(200);
    expect(patchRes.body.data.title).toBe('Updated title');

    const deleteRes = await request(app)
      .delete(`/api/v1/announcements/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(deleteRes.status).toBe(200);

    const listRes = await request(app).get('/api/v1/announcements').set('Authorization', `Bearer ${admin.accessToken}`);
    expect(listRes.body.data).toHaveLength(0);
  });

  it("returns 404 for an announcement from another admin's academy", async () => {
    const adminA = await registerAdmin('iso1a');
    const adminB = await registerAdmin('iso1b');
    const createRes = await request(app)
      .post('/api/v1/announcements')
      .set('Authorization', `Bearer ${adminA.accessToken}`)
      .send({ title: 'A only', message: 'msg', isForAll: true });

    const res = await request(app)
      .patch(`/api/v1/announcements/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${adminB.accessToken}`)
      .send({ title: 'hacked' });
    expect(res.status).toBe(404);
  });
});
