const prisma = require('../config/db');

async function canReadStudent(req, studentId) {
  if (req.user?.role === 'ADMIN' || req.user?.role === 'TEACHER') return true;
  if (req.user?.role === 'STUDENT') return req.user.id === studentId;
  if (req.user?.role !== 'PARENT') return false;
  const link = await prisma.parentStudent.findFirst({
    where: {
      parentId: req.user.id,
      studentId,
      student: { academyId: req.academyId, role: 'STUDENT' },
    },
    select: { id: true },
  });
  return Boolean(link);
}

module.exports = { canReadStudent };
