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

describe('POST /api/v1/ai/test-generator/analyze', () => {
  it('rejects a student', async () => {
    const admin = await registerAdmin('perm1');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'perm1');
    const res = await request(app)
      .post('/api/v1/ai/test-generator/analyze')
      .set('Authorization', `Bearer ${student.accessToken}`)
      .send({ text: 'short text' });
    expect(res.status).toBe(403);
  });

  it('classifies a short text as EASY', async () => {
    const admin = await registerAdmin('an1');
    const text = 'The cat sat on the mat.'; // well under 100 words
    const res = await request(app)
      .post('/api/v1/ai/test-generator/analyze')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ text });
    expect(res.status).toBe(200);
    expect(res.body.data.difficulty).toBe('EASY');
    expect(res.body.data.mcqCount).toBeGreaterThanOrEqual(3);
  });

  it('classifies text containing "theorem" as HARD regardless of length', async () => {
    const admin = await registerAdmin('an2');
    const res = await request(app)
      .post('/api/v1/ai/test-generator/analyze')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ text: 'Pythagoras theorem is short.' });
    expect(res.body.data.difficulty).toBe('HARD');
  });

  it('classifies a long text (>500 words) as HARD', async () => {
    const admin = await registerAdmin('an3');
    const text = Array(600).fill('word').join(' ');
    const res = await request(app)
      .post('/api/v1/ai/test-generator/analyze')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ text });
    expect(res.body.data.difficulty).toBe('HARD');
    expect(res.body.data.mcqCount).toBe(15); // clamped to the max
    expect(res.body.data.longCount).toBe(2);
  });
});

describe('POST /api/v1/ai/test-generator/generate', () => {
  it('extracts an MCQ from an "X is Y" sentence, a long question from a long leftover sentence, and a short question from the rest', async () => {
    const admin = await registerAdmin('gen1');
    const text =
      'Gravity is a force that attracts two bodies toward each other and governs the motion of planets around the sun in predictable elliptical orbits. Water boils at one hundred degrees celsius at sea level';

    const res = await request(app)
      .post('/api/v1/ai/test-generator/generate')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ text, mcqCount: 5, shortCount: 5, longCount: 5 });

    expect(res.status).toBe(200);
    const { questions } = res.body.data;

    const mcq = questions.find((q: { type: string }) => q.type === 'MCQ');
    expect(mcq).toMatchObject({
      text: 'What is a force that attracts two bodies toward each other and governs the motion of planets around the sun in predictable elliptical orbits?',
      options: ['Gravity', 'None of the above', 'Both A and B', 'Incorrect definition'],
      correctIndex: 0,
      marks: 1,
    });

    const short = questions.find((q: { type: string }) => q.type === 'SHORT');
    expect(short.text).toBe('Briefly explain: Water boils at one hundred degrees celsius at sea level');
    expect(short.marks).toBe(2);
  });

  it('rejects a non-staff caller', async () => {
    const admin = await registerAdmin('gen2');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'gen2');
    const res = await request(app)
      .post('/api/v1/ai/test-generator/generate')
      .set('Authorization', `Bearer ${student.accessToken}`)
      .send({ text: 'x', mcqCount: 1, shortCount: 1, longCount: 1 });
    expect(res.status).toBe(403);
  });
});

describe('POST /api/v1/ai/notes-summarizer', () => {
  it('classifies definitions and key points, and is available to any active role', async () => {
    const admin = await registerAdmin('sum1');
    const student = await createActiveUser(admin.accessToken, 'STUDENT', 'sum1');

    const text = ['Osmosis is the movement of water across a membrane.', 'PHOTOSYNTHESIS', 'A short note.'].join('\n');

    const res = await request(app)
      .post('/api/v1/ai/notes-summarizer')
      .set('Authorization', `Bearer ${student.accessToken}`)
      .send({ text });

    expect(res.status).toBe(200);
    expect(res.body.data.definitions).toEqual(['Osmosis is the movement of water across a membrane.']);
    expect(res.body.data.keyPoints).toEqual(['PHOTOSYNTHESIS', 'A short note.']);
    expect(res.body.data.isTooShort).toBe(false);
  });

  it('flags very sparse text as too short', async () => {
    const admin = await registerAdmin('sum2');
    const res = await request(app)
      .post('/api/v1/ai/notes-summarizer')
      .set('Authorization', `Bearer ${admin.accessToken}`)
      .send({ text: 'xyz abc qwerty' }); // no ' is ', no ':', too long for a key point, no trailing '.'
    expect(res.body.data.isTooShort).toBe(true);
    expect(res.body.data.definitions).toEqual([]);
    expect(res.body.data.keyPoints).toEqual([]);
  });
});
