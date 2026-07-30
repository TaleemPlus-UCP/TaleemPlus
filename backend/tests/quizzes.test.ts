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

async function createOfferingWithStudents(adminToken: string, suffix: string, teacherId: string, studentCount: number) {
  const sectionRes = await request(app)
    .post('/api/v1/class-sections')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ className: '10th', sectionLabel: suffix });
  const sectionId = sectionRes.body.data.id as string;

  const students = [];
  for (let i = 0; i < studentCount; i += 1) {
    students.push(await createActiveUser(adminToken, 'STUDENT', `${suffix}-${i}`));
  }
  await request(app)
    .put(`/api/v1/class-sections/${sectionId}/enrollment`)
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ studentIds: students.map((s) => s.id) });

  const offeringRes = await request(app)
    .post('/api/v1/classes')
    .set('Authorization', `Bearer ${adminToken}`)
    .send({ sectionId, teacherId, subject: 'Physics' });

  return { sectionId, offeringId: offeringRes.body.data.id as string, students };
}

const BASE_QUIZ = {
  title: 'Mid Term',
  subject: 'Physics',
  totalMarks: 20,
  testDate: '2026-07-15',
  questions: [
    { text: 'What is gravity?', type: 'MCQ', options: ['A force', 'A color', 'A sound'], correctIndex: 0, marks: 5 },
    { text: 'Explain Newton\'s first law.', type: 'SHORT', marks: 10, gradingKeywords: ['inertia', 'force', 'motion'] },
    { text: 'Discuss thermodynamics in detail.', type: 'LONG', marks: 5, gradingKeywords: ['energy', 'heat'] },
  ],
};

describe('POST /api/v1/quizzes', () => {
  it('rejects unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/quizzes');
    expect(res.status).toBe(401);
  });

  it('rejects a student trying to create a quiz', async () => {
    const admin = await registerAdmin('perm1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'perm1');
    const { offeringId } = await createOfferingWithStudents(admin.accessToken, 'perm1', teacher.id, 1);
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'perm1x');

    const res = await request(app)
      .post('/api/v1/quizzes')
      .set('Authorization', `Bearer ${student.accessToken}`)
      .send({ ...BASE_QUIZ, offeringId });
    expect(res.status).toBe(403);
  });

  it('rejects an MCQ question missing correctIndex/options', async () => {
    const admin = await registerAdmin('val1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'val1');
    const { offeringId } = await createOfferingWithStudents(admin.accessToken, 'val1', teacher.id, 1);

    const res = await request(app)
      .post('/api/v1/quizzes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({
        ...BASE_QUIZ,
        offeringId,
        questions: [{ text: 'Bad MCQ', type: 'MCQ', marks: 5 }],
      });
    expect(res.status).toBe(422);
  });

  it("rejects an offeringId from another admin's academy", async () => {
    const adminA = await registerAdmin('iso1a');
    const adminB = await registerAdmin('iso1b');
    const teacherB = await createActiveUser(adminB.accessToken, 'TEACHER', 'iso1');
    const { offeringId } = await createOfferingWithStudents(adminB.accessToken, 'iso1', teacherB.id, 1);

    const res = await request(app)
      .post('/api/v1/quizzes')
      .set('Authorization', `Bearer ${adminA.accessToken}`)
      .send({ ...BASE_QUIZ, offeringId });
    expect(res.status).toBe(400);
  });

  it('creates a quiz with ordered questions', async () => {
    const admin = await registerAdmin('create1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'create1');
    const { offeringId } = await createOfferingWithStudents(admin.accessToken, 'create1', teacher.id, 1);

    const res = await request(app)
      .post('/api/v1/quizzes')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ...BASE_QUIZ, offeringId });

    expect(res.status).toBe(201);
    expect(res.body.data.questions).toHaveLength(3);
    expect(res.body.data.questions.map((q: { order: number }) => q.order)).toEqual([0, 1, 2]);
    expect(res.body.data.totalMarks).toBe(20);
  });
});

describe('GET /api/v1/quizzes role scoping', () => {
  it('lets admin see all, and a teacher only their own offerings', async () => {
    const admin = await registerAdmin('scope1');
    const teacher1 = await createActiveUser(admin.accessToken, 'TEACHER', 'scope1a');
    const teacher2 = await createActiveUser(admin.accessToken, 'TEACHER', 'scope1b');
    const off1 = await createOfferingWithStudents(admin.accessToken, 'scope1a', teacher1.id, 1);
    const off2 = await createOfferingWithStudents(admin.accessToken, 'scope1b', teacher2.id, 1);

    await request(app).post('/api/v1/quizzes').set('Authorization', `Bearer ${admin.accessToken}`).send({ ...BASE_QUIZ, offeringId: off1.offeringId });
    await request(app).post('/api/v1/quizzes').set('Authorization', `Bearer ${admin.accessToken}`).send({ ...BASE_QUIZ, offeringId: off2.offeringId });

    const adminList = await request(app).get('/api/v1/quizzes').set('Authorization', `Bearer ${admin.accessToken}`);
    expect(adminList.body.data).toHaveLength(2);

    const teacher1List = await request(app).get('/api/v1/quizzes').set('Authorization', `Bearer ${teacher1.accessToken}`);
    expect(teacher1List.body.data).toHaveLength(1);

    const getOtherRes = await request(app)
      .get(`/api/v1/quizzes/${adminList.body.data.find((q: { offering: { id: string } }) => q.offering.id === off2.offeringId).id}`)
      .set('Authorization', `Bearer ${teacher1.accessToken}`);
    expect(getOtherRes.status).toBe(404);
  });
});

describe('PATCH/DELETE /api/v1/quizzes/:id', () => {
  it('replaces the question list on update', async () => {
    const admin = await registerAdmin('upd1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'upd1');
    const { offeringId } = await createOfferingWithStudents(admin.accessToken, 'upd1', teacher.id, 1);
    const createRes = await request(app).post('/api/v1/quizzes').set('Authorization', `Bearer ${admin.accessToken}`).send({ ...BASE_QUIZ, offeringId });

    const patchRes = await request(app)
      .patch(`/api/v1/quizzes/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ questions: [{ text: 'Only question now', type: 'SHORT', marks: 20, gradingKeywords: ['x'] }] });

    expect(patchRes.status).toBe(200);
    expect(patchRes.body.data.questions).toHaveLength(1);
  });

  it('deletes a quiz', async () => {
    const admin = await registerAdmin('del1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'del1');
    const { offeringId } = await createOfferingWithStudents(admin.accessToken, 'del1', teacher.id, 1);
    const createRes = await request(app).post('/api/v1/quizzes').set('Authorization', `Bearer ${admin.accessToken}`).send({ ...BASE_QUIZ, offeringId });

    const deleteRes = await request(app)
      .delete(`/api/v1/quizzes/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(deleteRes.status).toBe(200);

    const getRes = await request(app)
      .get(`/api/v1/quizzes/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(getRes.status).toBe(404);
  });
});

describe('POST /api/v1/quizzes/:id/questions/:questionId/grade-suggestion', () => {
  it('computes the AI Smart Grader formula correctly', async () => {
    const admin = await registerAdmin('grade1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'grade1');
    const { offeringId } = await createOfferingWithStudents(admin.accessToken, 'grade1', teacher.id, 1);
    const createRes = await request(app).post('/api/v1/quizzes').set('Authorization', `Bearer ${admin.accessToken}`).send({ ...BASE_QUIZ, offeringId });
    const shortQuestion = createRes.body.data.questions.find((q: { type: string }) => q.type === 'SHORT');

    // gradingKeywords = ['inertia', 'force', 'motion'], marks = 10; text matches 2 of 3.
    const res = await request(app)
      .post(`/api/v1/quizzes/${createRes.body.data.id}/questions/${shortQuestion.id}/grade-suggestion`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ocrText: 'An object in motion stays in motion due to inertia unless acted on.' });

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({
      matches: 2,
      keywordCount: 3,
      matchedKeywords: ['inertia', 'motion'],
      suggestedMarks: 6.67,
    });
  });

  it('rejects grading an MCQ question', async () => {
    const admin = await registerAdmin('grade2');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'grade2');
    const { offeringId } = await createOfferingWithStudents(admin.accessToken, 'grade2', teacher.id, 1);
    const createRes = await request(app).post('/api/v1/quizzes').set('Authorization', `Bearer ${admin.accessToken}`).send({ ...BASE_QUIZ, offeringId });
    const mcqQuestion = createRes.body.data.questions.find((q: { type: string }) => q.type === 'MCQ');

    const res = await request(app)
      .post(`/api/v1/quizzes/${createRes.body.data.id}/questions/${mcqQuestion.id}/grade-suggestion`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ ocrText: 'anything' });
    expect(res.status).toBe(400);
  });
});

describe('PUT/GET /api/v1/quizzes/:quizId/marks', () => {
  it('computes percentage/grade server-side and upserts without duplicating', async () => {
    const admin = await registerAdmin('marks1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'marks1');
    const { offeringId, students } = await createOfferingWithStudents(admin.accessToken, 'marks1', teacher.id, 2);
    const createRes = await request(app).post('/api/v1/quizzes').set('Authorization', `Bearer ${admin.accessToken}`).send({ ...BASE_QUIZ, offeringId });
    const quizId = createRes.body.data.id;

    const firstRes = await request(app)
      .put(`/api/v1/quizzes/${quizId}/marks`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ records: [{ studentId: students[0].id, marksObtained: 18 }, { studentId: students[1].id, marksObtained: 9 }] });

    expect(firstRes.status).toBe(200);
    const s0 = firstRes.body.data.find((m: { student: { id: string } }) => m.student.id === students[0].id);
    const s1 = firstRes.body.data.find((m: { student: { id: string } }) => m.student.id === students[1].id);
    expect(s0).toMatchObject({ marksObtained: 18, totalMarks: 20, percentage: 90, gradeLetter: 'A+' });
    expect(s1).toMatchObject({ marksObtained: 9, totalMarks: 20, percentage: 45, gradeLetter: 'F' });

    // Re-upsert with a changed value — must overwrite, not duplicate.
    await request(app)
      .put(`/api/v1/quizzes/${quizId}/marks`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ records: [{ studentId: students[0].id, marksObtained: 10 }] });

    const count = await prisma.testMark.count({ where: { quizId, studentId: students[0].id } });
    expect(count).toBe(1);

    const listRes = await request(app).get(`/api/v1/quizzes/${quizId}/marks`).set('Authorization', `Bearer ${admin.accessToken}`);
    expect(listRes.body.data).toHaveLength(2);
    const updated = listRes.body.data.find((m: { student: { id: string } }) => m.student.id === students[0].id);
    expect(updated.marksObtained).toBe(10);
    expect(updated.gradeLetter).toBe('D'); // 50%
  });

  it('rejects a student not enrolled in the section', async () => {
    const admin = await registerAdmin('marks2');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'marks2');
    const { offeringId } = await createOfferingWithStudents(admin.accessToken, 'marks2', teacher.id, 1);
    const outsider = await createActiveUser(admin.accessToken, 'STUDENT', 'marks2-outsider');
    const createRes = await request(app).post('/api/v1/quizzes').set('Authorization', `Bearer ${admin.accessToken}`).send({ ...BASE_QUIZ, offeringId });

    const res = await request(app)
      .put(`/api/v1/quizzes/${createRes.body.data.id}/marks`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ records: [{ studentId: outsider.id, marksObtained: 5 }] });
    expect(res.status).toBe(400);
  });
});

describe('GET /api/v1/marks/students/:studentId and DELETE /api/v1/marks/:id', () => {
  it('scopes student marks access correctly and restricts deletion to admins', async () => {
    const admin = await registerAdmin('smarks1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'smarks1');
    const { offeringId, students } = await createOfferingWithStudents(admin.accessToken, 'smarks1', teacher.id, 2);
    const parent = await createActiveUser(admin.accessToken, 'PARENT', 'smarks1');
    const createRes = await request(app).post('/api/v1/quizzes').set('Authorization', `Bearer ${admin.accessToken}`).send({ ...BASE_QUIZ, offeringId });
    await request(app)
      .put(`/api/v1/quizzes/${createRes.body.data.id}/marks`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ records: [{ studentId: students[0].id, marksObtained: 15 }] });

    const selfRes = await request(app)
      .get(`/api/v1/marks/students/${students[0].id}`)
      .set('Authorization', `Bearer ${students[0].accessToken}`);
    expect(selfRes.status).toBe(200);
    expect(selfRes.body.data).toHaveLength(1);
    expect(selfRes.body.data[0].quiz).not.toHaveProperty('questions');

    const otherStudentRes = await request(app)
      .get(`/api/v1/marks/students/${students[0].id}`)
      .set('Authorization', `Bearer ${students[1].accessToken}`);
    expect(otherStudentRes.status).toBe(403);

    const unlinkedParentRes = await request(app)
      .get(`/api/v1/marks/students/${students[0].id}`)
      .set('Authorization', `Bearer ${parent.accessToken}`);
    expect(unlinkedParentRes.status).toBe(403);

    await prisma.parentChildLink.create({ data: { parentId: parent.id, childId: students[0].id } });
    const linkedParentRes = await request(app)
      .get(`/api/v1/marks/students/${students[0].id}`)
      .set('Authorization', `Bearer ${parent.accessToken}`);
    expect(linkedParentRes.status).toBe(200);

    const markId = selfRes.body.data[0].id;
    const teacherDeleteRes = await request(app)
      .delete(`/api/v1/marks/${markId}`)
      .set('Authorization', `Bearer ${teacher.accessToken}`);
    expect(teacherDeleteRes.status).toBe(403);

    const adminDeleteRes = await request(app)
      .delete(`/api/v1/marks/${markId}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(adminDeleteRes.status).toBe(200);
  });
});
