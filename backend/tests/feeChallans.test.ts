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

async function setupSectionWithStudents(adminToken: string, suffix: string, count: number) {
  const sectionRes = await request(app)
    .post('/api/v1/class-sections')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ className: '10th', sectionLabel: 'A' });
  const sectionId = sectionRes.body.data.id as string;

  const students = [];
  for (let i = 0; i < count; i += 1) {
    students.push(await createActiveUser(adminToken, 'STUDENT', `${suffix}-${i}`));
  }

  await request(app)
    .put(`/api/v1/class-sections/${sectionId}/enrollment`)
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ studentIds: students.map((s) => s.id) });

  return { sectionId, students };
}

const BASE_GENERATE = { billingYear: 2026, billingMonth: 7, monthlyFee: 3000, admissionFee: 500, examFee: 200, fine: 0 };

describe('POST /api/v1/fee-challans/generate', () => {
  it('rejects unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/fee-challans');
    expect(res.status).toBe(401);
  });

  it('rejects a non-admin', async () => {
    const admin = await registerAdmin('perm1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'perm1');
    const res = await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${teacher.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId: '00000000-0000-0000-0000-000000000000' });
    expect(res.status).toBe(403);
  });

  it('rejects a section with no enrolled students', async () => {
    const admin = await registerAdmin('empty1');
    const sectionRes = await request(app)
      .post('/api/v1/class-sections')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ className: '10th', sectionLabel: 'A' });

    const res = await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId: sectionRes.body.data.id });
    expect(res.status).toBe(400);
  });

  it("rejects a sectionId from another admin's academy", async () => {
    const adminA = await registerAdmin('iso1a');
    const adminB = await registerAdmin('iso1b');
    const { sectionId } = await setupSectionWithStudents(adminB.accessToken, 'iso1', 1);

    const res = await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${adminA.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId });
    expect(res.status).toBe(404);
  });

  it('generates one challan per active enrolled student with correct totalAmount', async () => {
    const admin = await registerAdmin('gen1');
    const { sectionId, students } = await setupSectionWithStudents(admin.accessToken, 'gen1', 3);

    const res = await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId });

    expect(res.status).toBe(201);
    expect(res.body.data).toEqual({ generatedCount: 3, skippedCount: 0, eligibleCount: 3 });

    const listRes = await request(app)
      .get(`/api/v1/fee-challans?studentId=${students[0].id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(listRes.body.data).toHaveLength(1);
    expect(listRes.body.data[0].totalAmount).toBe(3700); // 3000 + 500 + 200
    expect(listRes.body.data[0].classLabelSnapshot).toBe('10th-A');
  });

  it('skips students already billed for the same (year, month), but not a different year', async () => {
    const admin = await registerAdmin('gen2');
    const { sectionId } = await setupSectionWithStudents(admin.accessToken, 'gen2', 2);

    const first = await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId });
    expect(first.body.data.generatedCount).toBe(2);

    const secondSameMonth = await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId });
    expect(secondSameMonth.body.data).toEqual({ generatedCount: 0, skippedCount: 2, eligibleCount: 2 });

    // Same billingMonth number, next year — must NOT be treated as already billed
    // (this is the year-boundary bug the legacy challanNumber-prefix scheme had).
    const nextYear = await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId, billingYear: 2027 });
    expect(nextYear.body.data).toEqual({ generatedCount: 2, skippedCount: 0, eligibleCount: 2 });
  });
});

describe('POST /api/v1/fee-challans (ad-hoc single-student challan)', () => {
  const BASE_CREATE = { billingYear: 2026, billingMonth: 8, monthlyFee: 1500 };

  it('rejects a non-admin', async () => {
    const admin = await registerAdmin('adhoc1');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'adhoc1');
    const res = await request(app)
      .post('/api/v1/fee-challans')
      .set('Authorization', `Bearer ${student.accessToken}`)
      .send({ ...BASE_CREATE, studentId: student.id });
    expect(res.status).toBe(403);
  });

  it('rejects a studentId from another academy', async () => {
    const adminA = await registerAdmin('adhoc2a');
    const adminB = await registerAdmin('adhoc2b');
    const student = await createActiveUser(adminB.accessToken, 'STUDENT', 'adhoc2');

    const res = await request(app)
      .post('/api/v1/fee-challans')
      .set('Authorization', `Bearer ${adminA.accessToken}`)
      .send({ ...BASE_CREATE, studentId: student.id });
    expect(res.status).toBe(400);
  });

  it('creates one challan for just the named student, deriving classLabelSnapshot from their section', async () => {
    const admin = await registerAdmin('adhoc3');
    const { students } = await setupSectionWithStudents(admin.accessToken, 'adhoc3', 2);

    const res = await request(app)
      .post('/api/v1/fee-challans')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_CREATE, studentId: students[0].id });

    expect(res.status).toBe(201);
    expect(res.body.data.student.id).toBe(students[0].id);
    expect(res.body.data.classLabelSnapshot).toBe('10th-A');
    expect(res.body.data.totalAmount).toBe(1500);
    expect(res.body.data.status).toBe('PENDING');

    // The other enrolled student must be untouched — this is single-student, not section-wide.
    const listRes = await request(app)
      .get(`/api/v1/fee-challans?studentId=${students[1].id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(listRes.body.data).toHaveLength(0);
  });

  it('rejects a second challan for the same student in the same billing month', async () => {
    const admin = await registerAdmin('adhoc4');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'adhoc4');

    const first = await request(app)
      .post('/api/v1/fee-challans')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_CREATE, studentId: student.id });
    expect(first.status).toBe(201);

    const second = await request(app)
      .post('/api/v1/fee-challans')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_CREATE, studentId: student.id });
    expect(second.status).toBe(409);
  });
});

describe('GET /api/v1/fee-challans role scoping', () => {
  it('scopes correctly for admin, student, parent, and blocks teachers', async () => {
    const admin = await registerAdmin('scope1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'scope1');
    const { sectionId, students } = await setupSectionWithStudents(admin.accessToken, 'scope1', 2);
    const parent = await createActiveUser(admin.accessToken, 'PARENT', 'scope1');

    await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId });

    const adminList = await request(app).get('/api/v1/fee-challans').set('Authorization', `Bearer ${admin.accessToken}`);
    expect(adminList.body.data).toHaveLength(2);

    const studentList = await request(app)
      .get('/api/v1/fee-challans')
      .set('Authorization', `Bearer ${students[0].accessToken}`);
    expect(studentList.body.data).toHaveLength(1);
    expect(studentList.body.data[0].student.id).toBe(students[0].id);

    const teacherList = await request(app)
      .get('/api/v1/fee-challans')
      .set('Authorization', `Bearer ${teacher.accessToken}`);
    expect(teacherList.status).toBe(403);

    const parentNoQuery = await request(app)
      .get('/api/v1/fee-challans')
      .set('Authorization', `Bearer ${parent.accessToken}`);
    expect(parentNoQuery.status).toBe(400);

    await prisma.parentChildLink.create({ data: { parentId: parent.id, childId: students[0].id } });

    const parentLinked = await request(app)
      .get(`/api/v1/fee-challans?studentId=${students[0].id}`)
      .set('Authorization', `Bearer ${parent.accessToken}`);
    expect(parentLinked.status).toBe(200);
    expect(parentLinked.body.data).toHaveLength(1);

    const parentUnlinked = await request(app)
      .get(`/api/v1/fee-challans?studentId=${students[1].id}`)
      .set('Authorization', `Bearer ${parent.accessToken}`);
    expect(parentUnlinked.status).toBe(403);
  });
});

describe('GET /api/v1/fee-challans/:id', () => {
  it('returns 404 when a student requests another student\'s challan', async () => {
    const admin = await registerAdmin('detail1');
    const { sectionId, students } = await setupSectionWithStudents(admin.accessToken, 'detail1', 2);
    await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId });

    const adminList = await request(app).get('/api/v1/fee-challans').set('Authorization', `Bearer ${admin.accessToken}`);
    const otherStudentChallan = adminList.body.data.find((c: { student: { id: string } }) => c.student.id === students[1].id);

    const res = await request(app)
      .get(`/api/v1/fee-challans/${otherStudentChallan.id}`)
      .set('Authorization', `Bearer ${students[0].accessToken}`);
    expect(res.status).toBe(404);
  });
});

describe('PATCH /api/v1/fee-challans/:id/status', () => {
  it('updates status as admin and rejects a non-admin', async () => {
    const admin = await registerAdmin('status1');
    const { sectionId, students } = await setupSectionWithStudents(admin.accessToken, 'status1', 1);
    await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId });

    const list = await request(app).get('/api/v1/fee-challans').set('Authorization', `Bearer ${admin.accessToken}`);
    const challanId = list.body.data[0].id;

    const patchRes = await request(app)
      .patch(`/api/v1/fee-challans/${challanId}/status`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ status: 'PAID' });
    expect(patchRes.status).toBe(200);
    expect(patchRes.body.data.status).toBe('PAID');

    const studentAttempt = await request(app)
      .patch(`/api/v1/fee-challans/${challanId}/status`)
      .set('Authorization', `Bearer ${students[0].accessToken}`)
      .send({ status: 'PENDING' });
    expect(studentAttempt.status).toBe(403);
  });
});

describe('GET /api/v1/fee-challans/sections/:sectionId/status', () => {
  it('shows every enrolled student with their challan (or null) for the month', async () => {
    const admin = await registerAdmin('roster1');
    const { sectionId } = await setupSectionWithStudents(admin.accessToken, 'roster1', 2);
    await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_GENERATE, sectionId, billingYear: 2026, billingMonth: 7 });

    const res = await request(app)
      .get(`/api/v1/fee-challans/sections/${sectionId}/status?year=2026&month=7`)
      .set('Authorization', `Bearer ${admin.accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.students).toHaveLength(2);
    for (const entry of res.body.data.students) {
      expect(entry.challan).not.toBeNull();
      expect(entry.challan.status).toBe('PENDING');
    }

    const emptyMonthRes = await request(app)
      .get(`/api/v1/fee-challans/sections/${sectionId}/status?year=2026&month=8`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    for (const entry of emptyMonthRes.body.data.students) {
      expect(entry.challan).toBeNull();
    }
  });
});
