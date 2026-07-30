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

describe('POST/GET /api/v1/ocr-documents', () => {
  it('rejects unauthenticated requests', async () => {
    const res = await request(app).get('/api/v1/ocr-documents');
    expect(res.status).toBe(401);
  });

  it('lets any active role create and list their own documents', async () => {
    const admin = await registerAdmin('own1');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'own1');

    const createRes = await request(app)
      .post('/api/v1/ocr-documents')
      .set('Authorization', `Bearer ${student.accessToken}`)
      .send({ title: 'Chapter 3 Notes', extractedText: 'Osmosis is the movement of water.' });
    expect(createRes.status).toBe(201);

    const listRes = await request(app).get('/api/v1/ocr-documents').set('Authorization', `Bearer ${student.accessToken}`);
    expect(listRes.body.data).toHaveLength(1);
    expect(listRes.body.data[0].title).toBe('Chapter 3 Notes');
  });

  it("isolates documents between owners — one user cannot see, update, or delete another's", async () => {
    const admin = await registerAdmin('iso1');
    const teacher = await createActiveUser(admin.accessToken, 'TEACHER', 'iso1');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'iso1');

    const createRes = await request(app)
      .post('/api/v1/ocr-documents')
      .set('Authorization', `Bearer ${teacher.accessToken}`)
      .send({ title: "Teacher's doc", extractedText: 'private text' });
    const docId = createRes.body.data.id;

    const studentList = await request(app).get('/api/v1/ocr-documents').set('Authorization', `Bearer ${student.accessToken}`);
    expect(studentList.body.data).toHaveLength(0);

    const getRes = await request(app).get(`/api/v1/ocr-documents/${docId}`).set('Authorization', `Bearer ${student.accessToken}`);
    expect(getRes.status).toBe(404);

    const patchRes = await request(app)
      .patch(`/api/v1/ocr-documents/${docId}`)
      .set('Authorization', `Bearer ${student.accessToken}`)
      .send({ title: 'hacked' });
    expect(patchRes.status).toBe(404);

    const deleteRes = await request(app).delete(`/api/v1/ocr-documents/${docId}`).set('Authorization', `Bearer ${student.accessToken}`);
    expect(deleteRes.status).toBe(404);
  });

  it('lets the owner update and delete their own document', async () => {
    const admin = await registerAdmin('own2');
    const createRes = await request(app)
      .post('/api/v1/ocr-documents')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'Original', extractedText: 'text' });

    const patchRes = await request(app)
      .patch(`/api/v1/ocr-documents/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ title: 'Renamed' });
    expect(patchRes.status).toBe(200);
    expect(patchRes.body.data.title).toBe('Renamed');

    const deleteRes = await request(app)
      .delete(`/api/v1/ocr-documents/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(deleteRes.status).toBe(200);

    const getRes = await request(app)
      .get(`/api/v1/ocr-documents/${createRes.body.data.id}`)
      .set('Authorization', `Bearer ${admin.accessToken}`);
    expect(getRes.status).toBe(404);
  });
});
