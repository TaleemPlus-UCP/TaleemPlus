const prisma = require('../config/db');

const getClasses = async (req, res, next) => {
  try {
    const classes = await prisma.class.findMany({
      where: { academyId: req.academyId },
      include: {
        primaryTeacher: {
          select: { id: true, fullName: true, email: true }
        },
        enrollments: {
          include: {
            student: { select: { id: true, fullName: true, email: true } }
          }
        }
      },
      orderBy: [{ className: 'asc' }, { section: 'asc' }]
    });

    const formatted = classes.map((c) => ({
      id: c.id,
      academy_id: c.academyId,
      class_name: c.className,
      section: c.section,
      subject: c.subject,
      primary_teacher_id: c.primaryTeacherId,
      primary_teacher_name: c.primaryTeacher?.fullName || '',
      primary_teacher_email: c.primaryTeacher?.email || '',
      student_ids: c.enrollments.map((e) => e.studentId),
      student_names: Object.fromEntries(c.enrollments.map((e) => [e.studentId, e.student.fullName])),
      created_at: c.createdAt
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    next(err);
  }
};

const createClass = async (req, res, next) => {
  try {
    const { className, section, subject, primaryTeacherId } = req.body;

    if (!className || !section || !subject) {
      return res.status(400).json({ success: false, message: 'Class name, section, and subject are required.' });
    }

    const newClass = await prisma.class.create({
      data: {
        academyId: req.academyId,
        className,
        section,
        subject,
        primaryTeacherId: primaryTeacherId || null
      },
      include: {
        primaryTeacher: { select: { id: true, fullName: true, email: true } }
      }
    });

    res.status(201).json({
      success: true,
      data: {
        id: newClass.id,
        academy_id: newClass.academyId,
        class_name: newClass.className,
        section: newClass.section,
        subject: newClass.subject,
        primary_teacher_id: newClass.primaryTeacherId,
        primary_teacher_name: newClass.primaryTeacher?.fullName || '',
        primary_teacher_email: newClass.primaryTeacher?.email || '',
        student_ids: [],
        student_names: {}
      }
    });
  } catch (err) {
    next(err);
  }
};

const deleteClass = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.class.findFirst({
      where: { id, academyId: req.academyId }
    });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Class not found in academy.' });
    }

    await prisma.class.delete({ where: { id } });
    res.json({ success: true, message: 'Class deleted successfully.' });
  } catch (err) {
    next(err);
  }
};

const enrollStudent = async (req, res, next) => {
  try {
    const { id: classId } = req.params;
    const { studentId, rollNumber } = req.body;

    const classEntity = await prisma.class.findFirst({
      where: { id: classId, academyId: req.academyId }
    });

    if (!classEntity) {
      return res.status(404).json({ success: false, message: 'Class not found.' });
    }

    const enrollment = await prisma.studentEnrollment.upsert({
      where: { classId_studentId: { classId, studentId } },
      create: { classId, studentId, rollNumber: rollNumber || null },
      update: { rollNumber: rollNumber || null }
    });

    res.json({ success: true, message: 'Student enrolled successfully.', data: enrollment });
  } catch (err) {
    next(err);
  }
};

module.exports = { getClasses, createClass, deleteClass, enrollStudent };
