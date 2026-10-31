const request = require('supertest');
const app = require('../src/app');

describe('TaleemPlus Backend Health & Auth API Suite', () => {
  it('GET /health should return 200 OK', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('status', 'ok');
  });

  it('POST /api/v1/auth/login without body should return 400 Bad Request', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({});
    expect(res.statusCode).toEqual(400);
    expect(res.body.success).toBe(false);
  });

  it('GET /api/v1/auth/me without Bearer token should return 401 Unauthorized', async () => {
    const res = await request(app).get('/api/v1/auth/me');
    expect(res.statusCode).toEqual(401);
  });
});
