const { authorizeRoles } = require('../src/middleware/roleMiddleware');

describe('authorizeRoles', () => {
  const makeResponse = () => {
    const res = { status: jest.fn(), json: jest.fn() };
    res.status.mockReturnValue(res);
    res.json.mockReturnValue(res);
    return res;
  };

  it('rejects a request when the user role is not allowed', () => {
    const req = { user: { role: 'STUDENT' } };
    const res = makeResponse();
    const next = jest.fn();

    authorizeRoles('ADMIN')(req, res, next);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ success: false }),
    );
    expect(next).not.toHaveBeenCalled();
  });

  it('continues when the user role is explicitly allowed', () => {
    const req = { user: { role: 'TEACHER' } };
    const res = makeResponse();
    const next = jest.fn();

    authorizeRoles('ADMIN', 'TEACHER')(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(res.status).not.toHaveBeenCalled();
    expect(res.json).not.toHaveBeenCalled();
  });
});
