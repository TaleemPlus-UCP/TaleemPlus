describe('internal ML service client', () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    delete process.env.ML_SERVICE_URL;
    delete process.env.ML_INTERNAL_TOKEN;
    jest.resetModules();
  });

  it('uses the internal credential and the authenticated academy scope', async () => {
    process.env.ML_SERVICE_URL = 'http://127.0.0.1:8100';
    process.env.ML_INTERNAL_TOKEN = 'test-only-token';
    global.fetch = jest.fn().mockResolvedValue({ ok: true, json: async () => ({ status: 'INSUFFICIENT_DATA' }) });
    const client = require('../src/services/mlServiceClient');
    const response = await client.request('/models/status', { academyId: 'academy-test' });
    expect(response.status).toBe('INSUFFICIENT_DATA');
    const [url, options] = global.fetch.mock.calls[0];
    expect(url.toString()).toContain('academy_id=academy-test');
    expect(options.headers.Authorization).toBe('Bearer test-only-token');
  });

  it('fails closed when internal service configuration is missing', async () => {
    const client = require('../src/services/mlServiceClient');
    await expect(client.request('/models/status', { academyId: 'academy-test' }))
      .rejects.toMatchObject({ status: 503 });
  });
});
