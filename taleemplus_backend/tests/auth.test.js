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

  it('keeps ML status, prediction, and training routes behind backend authentication', async () => {
    const status = await request(app).get('/api/v2/admin/ml/status');
    const prediction = await request(app).post('/api/v2/admin/ml/predict/fee-risk').send({});
    const training = await request(app).post('/api/v2/admin/ml/retrain').send({});
    expect(status.statusCode).toBe(401);
    expect(prediction.statusCode).toBe(401);
    expect(training.statusCode).toBe(401);
  });

  it('protects password changes, academy profile, and payment management endpoints', async () => {
    const paths = [
      ['post', '/api/v2/auth/verify-password'],
      ['put', '/api/v2/auth/password'],
      ['put', '/api/v2/auth/academy'],
      ['get', '/api/v2/fees/payment-settings'],
      ['put', '/api/v2/fees/payment-settings'],
      ['get', '/api/v2/fees/payment-proofs/pending'],
    ];
    for (const [method, path] of paths) {
      const response = await request(app)[method](path).send({});
      expect(response.statusCode).toBe(401);
    }
  });
});
