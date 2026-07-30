import request from 'supertest';
import { createApp } from '../src/app';
import { prisma } from '../src/config/database';

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

async function createOffering(adminToken: string, className: string, sectionLabel: string, subject: string, teacherId: string) {
  const sectionRes = await request(app)
    .post('/api/v1/class-sections')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ className, sectionLabel });
  const sectionId = sectionRes.body.data.id as string;

  const offeringRes = await request(app)
    .post('/api/v1/classes')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ sectionId, teacherId, subject });

  return { sectionId, offeringId: offeringRes.body.data.id as string };
}

const BASE_SLOT = {
  dayOfWeek: 1,
  startMinutes: 480, // 8:00
  endMinutes: 525, // 8:45
  effectiveFrom: '2026-01-01',
};

describe('POST /api/v1/timetable', () => {
  it('rejects unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/timetable');
    expect(res.status).toBe(401);
  });

  it('rejects a non-admin trying to create a slot', async () => {
    const admin = await registerAdmin('perm1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'perm1');
    const { offeringId } = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher.id);

    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${teacher.accessToken}`)
      .send({ ...BASE_SLOT, offeringId });
    expect(res.status).toBe(403);
  });

  it('creates a class slot with nested offering/section/teacher details', async () => {
    const admin = await registerAdmin('create1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'create1');
    const { offeringId } = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher.id);

    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId, room: 'Room 101' });

    expect(res.status).toBe(201);
    expect(res.body.data.isBreak).toBe(false);
    expect(res.body.data.offering.subject).toBe('Physics');
    expect(res.body.data.offering.teacher.id).toBe(teacher.id);
  });

  it('creates a break slot with no offering', async () => {
    const admin = await registerAdmin('create2');
    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, isBreak: true });
    expect(res.status).toBe(201);
    expect(res.body.data.offering).toBeNull();
  });

  it('rejects a non-break slot with no offeringId', async () => {
    const admin = await registerAdmin('val1');
    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT });
    expect(res.status).toBe(422);
  });

  it('rejects a break slot that also sets offeringId', async () => {
    const admin = await registerAdmin('val2');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'val2');
    const { offeringId } = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher.id);
    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, isBreak: true, offeringId });
    expect(res.status).toBe(422);
  });

  it('rejects endMinutes before startMinutes', async () => {
    const admin = await registerAdmin('val3');
    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, isBreak: true, endMinutes: 400 });
    expect(res.status).toBe(422);
  });

  it('rejects an offeringId from another academy with 400', async () => {
    const adminA = await registerAdmin('cross1a');
    const adminB = await registerAdmin('cross1b');
    const teacherB = await createActiveUser(adminB.accessToken, 'TEACHER', 'cross1');
    const { offeringId } = await createOffering(adminB.accessToken, '10th', 'A', 'Physics', teacherB.id);

    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${adminA.accessToken}`)
      .send({ ...BASE_SLOT, offeringId });
    expect(res.status).toBe(400);
  });
});

describe('conflict detection', () => {
  it('rejects a double-booked teacher at an overlapping time', async () => {
    const admin = await registerAdmin('conf1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'conf1');
    const off1 = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher.id);
    const off2 = await createOffering(admin.accessToken, '9th', 'B', 'Chemistry', teacher.id);

    await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off1.offeringId });

    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off2.offeringId, startMinutes: 500, endMinutes: 540 });
    expect(res.status).toBe(409);
    expect(res.body.message).toMatch(/already scheduled/i);
  });

  it('rejects a double-booked room at an overlapping time', async () => {
    const admin = await registerAdmin('conf2');
    const teacher1 = await createActiveUser(admin.accessToken, 'TEACHER', 'conf2a');
    const teacher2 = await createActiveUser(admin.accessToken, 'TEACHER', 'conf2b');
    const off1 = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher1.id);
    const off2 = await createOffering(admin.accessToken, '9th', 'B', 'Chemistry', teacher2.id);

    await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off1.offeringId, room: 'Room 5' });

    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off2.offeringId, room: 'room 5', startMinutes: 500, endMinutes: 540 });
    expect(res.status).toBe(409);
    expect(res.body.message).toMatch(/room/i);
  });

  it('rejects the same section double-booked with two subjects at an overlapping time', async () => {
    const admin = await registerAdmin('conf3');
    const teacher1 = await createActiveUser(admin.accessToken, 'TEACHER', 'conf3a');
    const teacher2 = await createActiveUser(admin.accessToken, 'TEACHER', 'conf3b');
    const sectionRes = await request(app)
      .post('/api/v1/class-sections')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ className: '10th', sectionLabel: 'A' });
    const sectionId = sectionRes.body.data.id;

    const off1 = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId, teacherId: teacher1.id, subject: 'Physics' });
    const off2 = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId, teacherId: teacher2.id, subject: 'Chemistry' });

    await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off1.body.data.id });

    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off2.body.data.id, startMinutes: 500, endMinutes: 540 });
    expect(res.status).toBe(409);
    expect(res.body.message).toMatch(/already has a session/i);
  });

  it('allows the same teacher/time on a different day of week', async () => {
    const admin = await registerAdmin('conf4');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'conf4');
    const off1 = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher.id);
    const off2 = await createOffering(admin.accessToken, '9th', 'B', 'Chemistry', teacher.id);

    await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off1.offeringId, dayOfWeek: 1 });

    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off2.offeringId, dayOfWeek: 2 });
    expect(res.status).toBe(201);
  });

  it('allows the same teacher/time/day when effective date ranges do not overlap (semester rotation)', async () => {
    const admin = await registerAdmin('conf5');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'conf5');
    const off1 = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher.id);
    const off2 = await createOffering(admin.accessToken, '9th', 'B', 'Chemistry', teacher.id);

    await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off1.offeringId, effectiveFrom: '2026-01-01', effectiveTo: '2026-03-31' });

    const res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off2.offeringId, effectiveFrom: '2026-04-01', effectiveTo: '2026-06-30' });
    expect(res.status).toBe(201);
  });
});

describe('PATCH/DELETE /api/v1/timetable/:id', () => {
  it('updates a slot without conflicting with itself', async () => {
    const admin = await registerAdmin('upd1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'upd1');
    const { offeringId } = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher.id);

    const createRes = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId, room: 'Room 1' });

    const patchRes = await request(app)
      .patch(`/api/v1/timetable/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ room: 'Room 2' });

    expect(patchRes.status).toBe(200);
    expect(patchRes.body.data.room).toBe('Room 2');
  });

  it('rejects an update that would create a new conflict', async () => {
    const admin = await registerAdmin('upd2');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'upd2');
    const off1 = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher.id);
    const off2 = await createOffering(admin.accessToken, '9th', 'B', 'Chemistry', teacher.id);

    await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off1.offeringId, startMinutes: 480, endMinutes: 525 });
    const slot2Res = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off2.offeringId, startMinutes: 600, endMinutes: 645 });

    const res = await request(app)
      .patch(`/api/v1/timetable/${slot2Res.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ startMinutes: 480, endMinutes: 525 });
    expect(res.status).toBe(409);
  });

  it('deletes a slot', async () => {
    const admin = await registerAdmin('del1');
    const createRes = await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, isBreak: true });

    const deleteRes = await request(app)
      .delete(`/api/v1/timetable/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(deleteRes.status).toBe(200);

    const listRes = await request(app).get('/api/v1/timetable').set('Authorization', `Bearer ${admin.accessToken}`);
    expect(listRes.body.data).toHaveLength(0);
  });

  it('cascades: deleting the underlying class offering removes its timetable slots', async () => {
    const admin = await registerAdmin('del2');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'del2');
    const { offeringId } = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher.id);

    await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId });

    await request(app).delete(`/api/v1/classes/${offeringId}`).set('Authorization', `Bearer ${admin.accessToken}`);

    const listRes = await request(app).get('/api/v1/timetable').set('Authorization', `Bearer ${admin.accessToken}`);
    expect(listRes.body.data).toHaveLength(0);
  });
});

describe('GET /api/v1/timetable role scoping', () => {
  it('scopes results correctly for admin, teacher, student, and parent', async () => {
    const admin = await registerAdmin('scope1');
    const teacher1 = await createActiveUser(admin.accessToken, 'TEACHER', 'scope1a');
    const teacher2 = await createActiveUser(admin.accessToken, 'TEACHER', 'scope1b');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'scope1');
    const otherStudent = await createActiveUser(admin.accessToken, 'STUDENT', 'scope1-other');
    const parent = await createActiveUser(admin.accessToken, 'PARENT', 'scope1');

    const off1 = await createOffering(admin.accessToken, '10th', 'A', 'Physics', teacher1.id);
    const off2 = await createOffering(admin.accessToken, '9th', 'B', 'Chemistry', teacher2.id);

    await request(app)
      .put(`/api/v1/class-sections/${off1.sectionId}/enrollment`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ studentIds: [student.id] });

    await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off1.offeringId, dayOfWeek: 1 });
    await request(app)
      .post('/api/v1/timetable')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_SLOT, offeringId: off2.offeringId, dayOfWeek: 2 });

    const adminList = await request(app).get('/api/v1/timetable').set('Authorization', `Bearer ${admin.accessToken}`);
    expect(adminList.body.data).toHaveLength(2);

    const teacher1List = await request(app)
      .get('/api/v1/timetable')
      .set('Authorization', `Bearer ${teacher1.accessToken}`);
    expect(teacher1List.body.data).toHaveLength(1);
    expect(teacher1List.body.data[0].offering.subject).toBe('Physics');

    const studentList = await request(app)
      .get('/api/v1/timetable')
      .set('Authorization', `Bearer ${student.accessToken}`);
    expect(studentList.body.data).toHaveLength(1);
    expect(studentList.body.data[0].offering.subject).toBe('Physics');

    const otherStudentList = await request(app)
      .get('/api/v1/timetable')
      .set('Authorization', `Bearer ${otherStudent.accessToken}`);
    expect(otherStudentList.body.data).toHaveLength(0);

    const parentNoQuery = await request(app)
      .get('/api/v1/timetable')
      .set('Authorization', `Bearer ${parent.accessToken}`);
    expect(parentNoQuery.status).toBe(400);

    await prisma.parentChildLink.create({ data: { parentId: parent.id, childId: student.id } });

    const parentLinked = await request(app)
      .get(`/api/v1/timetable?studentId=${student.id}`)
      .set('Authorization', `Bearer ${parent.accessToken}`);
    expect(parentLinked.status).toBe(200);
    expect(parentLinked.body.data).toHaveLength(1);

    const parentUnlinked = await request(app)
      .get(`/api/v1/timetable?studentId=${otherStudent.id}`)
      .set('Authorization', `Bearer ${parent.accessToken}`);
    expect(parentUnlinked.status).toBe(403);
  });
});

