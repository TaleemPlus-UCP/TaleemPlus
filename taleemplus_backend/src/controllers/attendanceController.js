const prisma = require('../config/db');
const { canReadStudent } = require('../utils/studentAccess');

const markAttendance = async (req, res, next) => {
  try {
    const { classId, records, logDate } = req.body;
    // records: [{ studentId, status: 'present' | 'absent' | 'late' }]

    if (!classId || !records || !logDate) {
      return res.status(400).json({ success: false, message: 'classId, logDate, and records array required.' });
    }

    const classObj = await prisma.class.findFirst({
      where: { id: classId, academyId: req.academyId }
    });

    if (!classObj) {
      return res.status(404).json({ success: false, message: 'Class not found in academy.' });
    }

    const savedRecords = await prisma.$transaction(
      records.map((r) => {
        const upperStatus = (r.status || 'PRESENT').toUpperCase();
        return prisma.attendanceRecord.upsert({
          where: {
            classId_studentId_logDate: {
              classId,
              studentId: r.studentId,
              logDate
            }
          },
          create: {
            academyId: req.academyId,
            classId,
            studentId: r.studentId,
            logDate,
            status: upperStatus,
            markedById: req.user.id
          },
          update: {
            status: upperStatus,
            markedById: req.user.id,
            recordedAt: new Date()
          }
        });
      })
    );

    res.json({
      success: true,
      message: 'Attendance saved successfully.',
      data: savedRecords
    });
  } catch (err) {
    next(err);
  }
};

const getStudentAttendance = async (req, res, next) => {
  try {
    const { studentId } = req.params;
    if (!(await canReadStudent(req, studentId))) {
      return res.status(403).json({ success: false, message: 'You cannot access this student’s attendance.' });
    }

    const records = await prisma.attendanceRecord.findMany({
      where: {
        academyId: req.academyId,
        studentId
      },
      include: {
        class: { select: { className: true, section: true, subject: true } }
      },
      orderBy: { logDate: 'desc' }
    });

    const formatted = records.map((r) => ({
      id: r.id,
      academy_id: r.academyId,
      class_id: r.classId,
      student_id: r.studentId,
      log_date: r.logDate,
      status: r.status.toLowerCase(),
      marked_by_uid: r.markedById,
      recorded_at: r.recordedAt
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    next(err);
  }
};

const getClassAttendance = async (req, res, next) => {
  try {
    const { classId, logDate } = req.query;

    if (!classId || !logDate) {
      return res.status(400).json({ success: false, message: 'classId and logDate required.' });
    }

    const records = await prisma.attendanceRecord.findMany({
      where: {
        academyId: req.academyId,
        classId: String(classId),
        logDate: String(logDate)
      },
      include: {
        student: { select: { id: true, fullName: true } }
      }
    });

    res.json({ success: true, data: records });
  } catch (err) {
    next(err);
  }
};

module.exports = { markAttendance, getStudentAttendance, getClassAttendance };
