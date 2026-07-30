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

async function createActiveUser(adminToken: string, role: 'TEACHER' | 'STUDENT', suffix: string) {
  const res = await request(app)
    .post('/api/v1/users')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({
      fullName: `${role} ${suffix}`,
      email: `${role.toLowerCase()}-${suffix}@test.local`,
      password: 'Passw0rd!',
      phoneNumber: '+920000002000',
      role,
    });
  const login = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: `${role.toLowerCase()}-${suffix}@test.local`, password: 'Passw0rd!' });
  return { id: res.body.data.id as string, accessToken: login.body.data.tokens.accessToken as string };
}

async function createSection(adminToken: string, className: string, sectionLabel: string) {
  const res = await request(app)
    .post('/api/v1/class-sections')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ className, sectionLabel });
  return res.body.data as { id: string };
}

describe('POST/GET /api/v1/class-sections', () => {
  it('rejects unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/class-sections');
    expect(res.status).toBe(401);
  });

  it('rejects a non-admin role with 403', async () => {
    const admin = await registerAdmin('sec1');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'sec1');
    const res = await request(app)
      .get('/api/v1/class-sections')
      .set('Authorization', `Bearer ${student.accessToken}`);
    expect(res.status).toBe(403);
  });

  it('creates a section and rejects a duplicate className+sectionLabel with 409', async () => {
    const admin = await registerAdmin('sec2');
    const createRes = await request(app)
      .post('/api/v1/class-sections')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ className: '10th', sectionLabel: 'A' });
    expect(createRes.status).toBe(201);
    expect(createRes.body.data.studentIds).toEqual([]);
    expect(createRes.body.data.enrollmentCount).toBe(0);

    const dupRes = await request(app)
      .post('/api/v1/class-sections')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ className: '10th', sectionLabel: 'A' });
    expect(dupRes.status).toBe(409);
  });

  it('filters the list by className', async () => {
    const admin = await registerAdmin('sec3');
    await createSection(admin.accessToken, '10th', 'A');
    await createSection(admin.accessToken, '9th', 'A');

    const res = await request(app)
      .get('/api/v1/class-sections?className=10th')
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].className).toBe('10th');
  });
});

describe('PUT /api/v1/class-sections/:id/enrollment', () => {
  it('enrolls valid ACTIVE students from the same academy', async () => {
    const admin = await registerAdmin('enr1');
    const section = await createSection(admin.accessToken, '10th', 'A');
    const student1 = await createActiveUser(admin.accessToken, 'STUDENT', 'enr1a');
    const student2 = await createActiveUser(admin.accessToken, 'STUDENT', 'enr1b');

    const res = await request(app)
      .put(`/api/v1/class-sections/${section.id}/enrollment`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ studentIds: [student1.id, student2.id] });

    expect(res.status).toBe(200);
    expect(res.body.data.enrollmentCount).toBe(2);
    expect(res.body.data.studentIds.sort()).toEqual([student1.id, student2.id].sort());
  });

  it('rejects a non-student id (e.g. a teacher) with 400', async () => {
    const admin = await registerAdmin('enr2');
    const section = await createSection(admin.accessToken, '10th', 'A');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'enr2');

    const res = await request(app)
      .put(`/api/v1/class-sections/${section.id}/enrollment`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ studentIds: [teacher.id] });
    expect(res.status).toBe(400);
  });

  it('rejects a student id from another academy with 400', async () => {
    const adminA = await registerAdmin('enr3a');
    const adminB = await registerAdmin('enr3b');
    const section = await createSection(adminA.accessToken, '10th', 'A');
    const outsideStudent = await createActiveUser(adminB.accessToken, 'STUDENT', 'enr3');

    const res = await request(app)
      .put(`/api/v1/class-sections/${section.id}/enrollment`)
      .set('Authorization', `Bearer ${adminA.accessToken}`)
      .send({ studentIds: [outsideStudent.id] });
    expect(res.status).toBe(400);
  });

  it("returns 404 when the section belongs to another admin's academy", async () => {
    const adminA = await registerAdmin('enr4a');
    const adminB = await registerAdmin('enr4b');
    const section = await createSection(adminA.accessToken, '10th', 'A');

    const res = await request(app)
      .put(`/api/v1/class-sections/${section.id}/enrollment`)
      .set('Authorization', `Bearer ${adminB.accessToken}`)
      .send({ studentIds: [] });
    expect(res.status).toBe(404);
  });
});

describe('DELETE /api/v1/class-sections/:id', () => {
  it('cascades: deleting a section removes its offerings too', async () => {
    const admin = await registerAdmin('del1');
    const section = await createSection(admin.accessToken, '10th', 'A');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'del1');

    const offeringRes = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId: section.id, teacherId: teacher.id, subject: 'Physics' });
    expect(offeringRes.status).toBe(201);

    const deleteRes = await request(app)
      .delete(`/api/v1/class-sections/${section.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(deleteRes.status).toBe(200);

    const getOfferingRes = await request(app)
      .get(`/api/v1/classes/${offeringRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(getOfferingRes.status).toBe(404);
  });
});

describe('POST /api/v1/classes', () => {
  it('creates an offering and rejects an ineligible teacherId with 400', async () => {
    const admin = await registerAdmin('off1');
    const section = await createSection(admin.accessToken, '10th', 'A');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'off1');

    const res = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId: section.id, teacherId: student.id, subject: 'Physics' });
    expect(res.status).toBe(400);
  });

  it("returns 404 when sectionId belongs to another admin's academy", async () => {
    const adminA = await registerAdmin('off2a');
    const adminB = await registerAdmin('off2b');
    const section = await createSection(adminA.accessToken, '10th', 'A');
    const teacherB = await createActiveUser(adminB.accessToken, 'TEACHER', 'off2');

    const res = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${adminB.accessToken}`)
      .send({ sectionId: section.id, teacherId: teacherB.id, subject: 'Physics' });
    expect(res.status).toBe(404);
  });
});

describe('GET /api/v1/classes role scoping', () => {
  it('lets an admin see every offering, and a teacher see only their own', async () => {
    const admin = await registerAdmin('scope1');
    const sectionA = await createSection(admin.accessToken, '10th', 'A');
    const teacher1 = await createActiveUser(admin.accessToken, 'TEACHER', 'scope1a');
    const teacher2 = await createActiveUser(admin.accessToken, 'TEACHER', 'scope1b');

    await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId: sectionA.id, teacherId: teacher1.id, subject: 'Physics' });
    await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId: sectionA.id, teacherId: teacher2.id, subject: 'Chemistry' });

    const adminList = await request(app).get('/api/v1/classes').set('Authorization', `Bearer ${admin.accessToken}`);
    expect(adminList.body.data).toHaveLength(2);

    const teacher1List = await request(app)
      .get('/api/v1/classes')
      .set('Authorization', `Bearer ${teacher1.accessToken}`);
    expect(teacher1List.body.data).toHaveLength(1);
    expect(teacher1List.body.data[0].subject).toBe('Physics');
  });

  it('blocks a teacher from GET /classes/:id (admin-only detail view)', async () => {
    const admin = await registerAdmin('scope2');
    const section = await createSection(admin.accessToken, '10th', 'A');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'scope2');
    const offeringRes = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId: section.id, teacherId: teacher.id, subject: 'Physics' });

    const res = await request(app)
      .get(`/api/v1/classes/${offeringRes.body.data.id}`)
      .set('Authorization', `Bearer ${teacher.accessToken}`);
    expect(res.status).toBe(403);
  });
});

describe('PATCH/DELETE /api/v1/classes/:id', () => {
  it('updates subject and teacher, reflecting enrollment count from the section', async () => {
    const admin = await registerAdmin('upd1');
    const section = await createSection(admin.accessToken, '10th', 'A');
    const teacher1 = await createActiveUser(admin.accessToken, 'TEACHER', 'upd1a');
    const teacher2 = await createActiveUser(admin.accessToken, 'TEACHER', 'upd1b');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'upd1');

    await request(app)
      .put(`/api/v1/class-sections/${section.id}/enrollment`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ studentIds: [student.id] });

    const offeringRes = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId: section.id, teacherId: teacher1.id, subject: 'Physics' });

    const patchRes = await request(app)
      .patch(`/api/v1/classes/${offeringRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ subject: 'Advanced Physics', teacherId: teacher2.id });

    expect(patchRes.status).toBe(200);
    expect(patchRes.body.data.subject).toBe('Advanced Physics');
    expect(patchRes.body.data.teacher.id).toBe(teacher2.id);
    expect(patchRes.body.data.section.enrollmentCount).toBe(1);
  });

  it('deletes an offering without touching its section', async () => {
    const admin = await registerAdmin('del2');
    const section = await createSection(admin.accessToken, '10th', 'A');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'del2');
    const offeringRes = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId: section.id, teacherId: teacher.id, subject: 'Physics' });

    const deleteRes = await request(app)
      .delete(`/api/v1/classes/${offeringRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(deleteRes.status).toBe(200);

    const sectionsRes = await request(app)
      .get('/api/v1/class-sections')
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(sectionsRes.body.data.some((s: { id: string }) => s.id === section.id)).toBe(true);
  });
});
