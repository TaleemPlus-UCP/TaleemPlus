jest.mock('../src/config/db', () => ({
  parentStudent: { findFirst: jest.fn() },
}));

const prisma = require('../src/config/db');
const { canReadStudent } = require('../src/utils/studentAccess');

describe('academy student record access', () => {
  beforeEach(() => jest.clearAllMocks());

  test('students can only read their own records', async () => {
    expect(await canReadStudent({ user: { id: 'student-a', role: 'STUDENT' } }, 'student-a')).toBe(true);
    expect(await canReadStudent({ user: { id: 'student-a', role: 'STUDENT' } }, 'student-b')).toBe(false);
    expect(prisma.parentStudent.findFirst).not.toHaveBeenCalled();
  });

  test('parents require a verified link scoped to their academy', async () => {
    const req = { user: { id: 'parent-a', role: 'PARENT' }, academyId: 'academy-a' };
    prisma.parentStudent.findFirst.mockResolvedValueOnce({ id: 'link-a' });
    expect(await canReadStudent(req, 'student-a')).toBe(true);
    expect(prisma.parentStudent.findFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({
        parentId: 'parent-a', studentId: 'student-a',
        student: { academyId: 'academy-a', role: 'STUDENT' },
      }),
    }));
    prisma.parentStudent.findFirst.mockResolvedValueOnce(null);
    expect(await canReadStudent(req, 'student-b')).toBe(false);
  });

  test('academy staff can read student reports', async () => {
    expect(await canReadStudent({ user: { role: 'ADMIN' } }, 'student-a')).toBe(true);
    expect(await canReadStudent({ user: { role: 'TEACHER' } }, 'student-a')).toBe(true);
  });
});
