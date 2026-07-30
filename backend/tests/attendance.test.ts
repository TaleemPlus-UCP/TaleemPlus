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

async function setupClassroom(suffix: string) {
  const admin = await registerAdmin(suffix);
  const teacher = await createActiveUser(admin.accessToken, 'TEACHER', suffix);
  const student1 = await createActiveUser(admin.accessToken, 'STUDENT', `${suffix}a`);
  const student2 = await createActiveUser(admin.accessToken, 'STUDENT', `${suffix}b`);

  const sectionRes = await request(app)
    .post('/api/v1/class-sections')
    .set('Authorization', `Bearer ${admin.accessToken}`)
    .send({ className: '10th', sectionLabel: 'A' });
  const sectionId = sectionRes.body.data.id as string;

  await request(app)
    .put(`/api/v1/class-sections/${sectionId}/enrollment`)
    .set('Authorization', `Bearer ${admin.accessToken}`)
    .send({ studentIds: [student1.id, student2.id] });

  const offeringRes = await request(app)
    .post('/api/v1/classes')
    .set('Authorization', `Bearer ${admin.accessToken}`)
    .send({ sectionId, teacherId: teacher.id, subject: 'Physics' });
  const offeringId = offeringRes.body.data.id as string;

  return { admin, teacher, student1, student2, sectionId, offeringId };
}

describe('POST/GET /api/v1/attendance', () => {
  it('rejects unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/attendance?offeringId=00000000-0000-0000-0000-000000000000&logDate=2026-01-01');
    expect(res.status).toBe(401);
  });

  it('rejects a student trying to mark attendance', async () => {
    const { student1, offeringId } = await setupClassroom('mark1');
    const res = await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${student1.accessToken}`)
      .send({ offeringId, logDate: '2026-01-15', records: [{ studentId: student1.id, status: 'PRESENT' }] });
    expect(res.status).toBe(403);
  });

  it('marks a day sheet as admin and returns every enrolled student', async () => {
    const { admin, student1, student2, offeringId } = await setupClassroom('mark2');

    const res = await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        offeringId,
        logDate: '2026-01-15',
        records: [
          { studentId: student1.id, status: 'PRESENT' },
          { studentId: student2.id, status: 'LATE' },
        ],
      });

    expect(res.status).toBe(200);
    expect(res.body.data.students).toHaveLength(2);
    const byId = Object.fromEntries(res.body.data.students.map((s: { studentId: string; status: string }) => [s.studentId, s.status]));
    expect(byId[student1.id]).toBe('PRESENT');
    expect(byId[student2.id]).toBe('LATE');
  });

  it('allows a teacher to mark attendance too', async () => {
    const { teacher, student1, offeringId } = await setupClassroom('mark3');
    const res = await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${teacher.accessToken}`)
      .send({ offeringId, logDate: '2026-01-15', records: [{ studentId: student1.id, status: 'ABSENT' }] });
    expect(res.status).toBe(200);
  });

  it('rejects a studentId that is not enrolled in the section', async () => {
    const { admin, offeringId } = await setupClassroom('mark4');
    const outsider = await createActiveUser(admin.accessToken, 'STUDENT', 'mark4-outsider');

    const res = await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ offeringId, logDate: '2026-01-15', records: [{ studentId: outsider.id, status: 'PRESENT' }] });
    expect(res.status).toBe(400);
  });

  it("returns 404 for an offeringId from another admin's academy", async () => {
    const { offeringId } = await setupClassroom('mark5a');
    const otherAdmin = await registerAdmin('mark5b');

    const res = await request(app)
      .get(`/api/v1/attendance?offeringId=${offeringId}&logDate=2026-01-15`)
      .set('Authorization', `Bearer ${otherAdmin.accessToken}`);
    expect(res.status).toBe(404);
  });

  it('re-marking the same day overwrites instead of duplicating', async () => {
    const { admin, student1, student2, offeringId } = await setupClassroom('mark6');

    await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        offeringId,
        logDate: '2026-01-15',
        records: [
          { studentId: student1.id, status: 'PRESENT' },
          { studentId: student2.id, status: 'PRESENT' },
        ],
      });

    const secondRes = await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        offeringId,
        logDate: '2026-01-15',
        records: [{ studentId: student1.id, status: 'ABSENT' }],
      });

    expect(secondRes.status).toBe(200);
    const student1Entry = secondRes.body.data.students.find(
      (s: { studentId: string }) => s.studentId === student1.id,
    );
    expect(student1Entry.status).toBe('ABSENT');

    const dayCount = await prisma.attendanceRecord.count({ where: { offeringId, studentId: student1.id } });
    expect(dayCount).toBe(1); // upsert, not a duplicate row
  });

  it('defaults unmarked enrolled students to ABSENT on GET', async () => {
    const { admin, student1, offeringId } = await setupClassroom('day1');
    const res = await request(app)
      .get(`/api/v1/attendance?offeringId=${offeringId}&logDate=2026-02-01`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(res.status).toBe(200);
    const entry = res.body.data.students.find((s: { studentId: string }) => s.studentId === student1.id);
    expect(entry.status).toBe('ABSENT');
    expect(entry.recordedAt).toBeNull();
  });
});

describe('GET /api/v1/attendance/students/:studentId/monthly', () => {
  it('lets a student view their own monthly attendance with a correct summary', async () => {
    const { admin, student1, student2, offeringId } = await setupClassroom('mo1');
    await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        offeringId,
        logDate: '2026-03-05',
        records: [
          { studentId: student1.id, status: 'PRESENT' },
          { studentId: student2.id, status: 'PRESENT' },
        ],
      });
    await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ offeringId, logDate: '2026-03-06', records: [{ studentId: student1.id, status: 'ABSENT' }] });
    await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ offeringId, logDate: '2026-03-07', records: [{ studentId: student1.id, status: 'LATE' }] });

    const res = await request(app)
      .get(`/api/v1/attendance/students/${student1.id}/monthly?year=2026&month=3`)
      .set('Authorization', `Bearer ${student1.accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.records).toHaveLength(3);
    expect(res.body.data.summary).toEqual({
      totalDays: 3,
      presentCount: 1,
      absentCount: 1,
      lateCount: 1,
      percentage: 66.7,
    });
  });

  it('blocks a student from viewing another student\'s attendance', async () => {
    const { student1, student2 } = await setupClassroom('mo2');
    const res = await request(app)
      .get(`/api/v1/attendance/students/${student2.id}/monthly`)
      .set('Authorization', `Bearer ${student1.accessToken}`);
    expect(res.status).toBe(403);
  });

  it('lets a linked parent view the child\'s attendance, and blocks an unlinked parent', async () => {
    const { admin, student1 } = await setupClassroom('mo3');
    const parent = await createActiveUser(admin.accessToken, 'PARENT', 'mo3-linked');
    const unlinkedParent = await createActiveUser(admin.accessToken, 'PARENT', 'mo3-unlinked');

    await prisma.parentChildLink.create({ data: { parentId: parent.id, childId: student1.id } });

    const linkedRes = await request(app)
      .get(`/api/v1/attendance/students/${student1.id}/monthly`)
      .set('Authorization', `Bearer ${parent.accessToken}`);
    expect(linkedRes.status).toBe(200);

    const unlinkedRes = await request(app)
      .get(`/api/v1/attendance/students/${student1.id}/monthly`)
      .set('Authorization', `Bearer ${unlinkedParent.accessToken}`);
    expect(unlinkedRes.status).toBe(403);
  });

  it("returns 404 when an admin from another academy targets the student", async () => {
    const { student1 } = await setupClassroom('mo4a');
    const otherAdmin = await registerAdmin('mo4b');
    const res = await request(app)
      .get(`/api/v1/attendance/students/${student1.id}/monthly`)
      .set('Authorization', `Bearer ${otherAdmin.accessToken}`);
    expect(res.status).toBe(404);
  });
});

describe('GET /api/v1/attendance/students/:studentId/yearly', () => {
  it('buckets records into the correct months across a year', async () => {
    const { admin, student1, offeringId } = await setupClassroom('yr1');

    await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ offeringId, logDate: '2026-01-10', records: [{ studentId: student1.id, status: 'PRESENT' }] });
    await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ offeringId, logDate: '2026-01-11', records: [{ studentId: student1.id, status: 'ABSENT' }] });
    await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ offeringId, logDate: '2026-06-01', records: [{ studentId: student1.id, status: 'PRESENT' }] });

    const res = await request(app)
      .get(`/api/v1/attendance/students/${student1.id}/yearly?year=2026`)
      .set('Authorization', `Bearer ${admin.accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.months).toHaveLength(12);
    const jan = res.body.data.months.find((m: { month: number }) => m.month === 1);
    const jun = res.body.data.months.find((m: { month: number }) => m.month === 6);
    const feb = res.body.data.months.find((m: { month: number }) => m.month === 2);
    expect(jan).toMatchObject({ totalDays: 2, presentCount: 1, absentCount: 1, lateCount: 0 });
    expect(jun).toMatchObject({ totalDays: 1, presentCount: 1 });
    expect(feb).toMatchObject({ totalDays: 0, presentCount: 0, absentCount: 0, lateCount: 0, percentage: 0 });
  });
});
