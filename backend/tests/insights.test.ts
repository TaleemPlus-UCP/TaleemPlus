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

describe('GET /api/v1/insights/at-risk-students', () => {
  it('rejects a non-admin', async () => {
    const admin = await registerAdmin('perm1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'perm1');
    const res = await request(app).get('/api/v1/insights/at-risk-students').set('Authorization', `Bearer ${teacher.accessToken}`);
    expect(res.status).toBe(403);
  });

  it('flags students averaging below 50% and reports the weakest subject', async () => {
    const admin = await registerAdmin('risk1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'risk1');

    const sectionRes = await request(app)
      .post('/api/v1/class-sections')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ className: '10th', sectionLabel: 'A' });
    const sectionId = sectionRes.body.data.id;

    const weakStudent = await createActiveUser(admin.accessToken, 'STUDENT', 'risk1-weak');
    const strongStudent = await createActiveUser(admin.accessToken, 'STUDENT', 'risk1-strong');
    await request(app)
      .put(`/api/v1/class-sections/${sectionId}/enrollment`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ studentIds: [weakStudent.id, strongStudent.id] });

    const physicsOffering = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId, teacherId: teacher.id, subject: 'Physics' });
    const chemistryOffering = await request(app)
      .post('/api/v1/classes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId, teacherId: teacher.id, subject: 'Chemistry' });

    const physicsQuiz = await request(app)
      .post('/api/v1/quizzes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        offeringId: physicsOffering.body.data.id,
        title: 'Physics Test',
        subject: 'Physics',
        totalMarks: 100,
        testDate: '2026-07-01',
        questions: [{ text: 'Q', type: 'SHORT', marks: 100, gradingKeywords: [] }],
      });
    const chemistryQuiz = await request(app)
      .post('/api/v1/quizzes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        offeringId: chemistryOffering.body.data.id,
        title: 'Chemistry Test',
        subject: 'Chemistry',
        totalMarks: 100,
        testDate: '2026-07-02',
        questions: [{ text: 'Q', type: 'SHORT', marks: 100, gradingKeywords: [] }],
      });

    await request(app)
      .put(`/api/v1/quizzes/${physicsQuiz.body.data.id}/marks`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ records: [{ studentId: weakStudent.id, marksObtained: 30 }, { studentId: strongStudent.id, marksObtained: 90 }] });
    await request(app)
      .put(`/api/v1/quizzes/${chemistryQuiz.body.data.id}/marks`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ records: [{ studentId: weakStudent.id, marksObtained: 20 }, { studentId: strongStudent.id, marksObtained: 95 }] });

    const res = await request(app)
      .get('/api/v1/insights/at-risk-students')
      .set('Authorization', `Bearer ${admin.accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.students).toHaveLength(1);
    expect(res.body.data.students[0]).toMatchObject({ studentId: weakStudent.id, averagePercentage: 25 });
    expect(res.body.data.weakestSubject.subject).toBe('Chemistry'); // weak(20)+strong(95) avg 57.5 vs Physics (30+90)/2=60
    expect(res.body.data.academyAveragePercentage).toBe(58.75); // mean of [30, 90, 20, 95]
  });
});

describe('GET /api/v1/insights/revenue-forecast', () => {
  it('computes collection efficiency and a projected forecast', async () => {
    const admin = await registerAdmin('rev1');
    const sectionRes = await request(app)
      .post('/api/v1/class-sections')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ className: '10th', sectionLabel: 'A' });
    const student1 = await createActiveUser(admin.accessToken, 'STUDENT', 'rev1a');
    const student2 = await createActiveUser(admin.accessToken, 'STUDENT', 'rev1b');
    await request(app)
      .put(`/api/v1/class-sections/${sectionRes.body.data.id}/enrollment`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ studentIds: [student1.id, student2.id] });

    await request(app)
      .post('/api/v1/fee-challans/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ sectionId: sectionRes.body.data.id, billingYear: 2026, billingMonth: 7, monthlyFee: 1000 });

    const listRes = await request(app).get('/api/v1/fee-challans').set('Authorization', `Bearer ${admin.accessToken}`);
    const oneChallanId = listRes.body.data[0].id;
    await request(app)
      .patch(`/api/v1/fee-challans/${oneChallanId}/status`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ status: 'PAID' });

    const res = await request(app)
      .get('/api/v1/insights/revenue-forecast')
      .set('Authorization', `Bearer ${admin.accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.totalPayable).toBe(2000);
    expect(res.body.data.totalPaid).toBe(1000);
    expect(res.body.data.collectionEfficiency).toBe(50);
    expect(res.body.data.pendingAmount).toBe(1000);
    expect(res.body.data.projectedRevenue).toBe(2000);
    expect(res.body.data.predictedCollection).toBe(1700); // 2000 * 0.85
  });
});
