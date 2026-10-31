const prisma = require('../config/db');

const getTimetable = async (req, res, next) => {
  try {
    const { classId, teacherId } = req.query;
    const whereClause = { academyId: req.academyId };
    if (classId) whereClause.classId = String(classId);
    if (teacherId) whereClause.teacherId = String(teacherId);

    const slots = await prisma.timetableSlot.findMany({
      where: whereClause,
      include: {
        teacher: { select: { fullName: true } },
        class: { select: { className: true, section: true } }
      },
      orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }]
    });

    res.json({ success: true, data: slots });
  } catch (err) {
    next(err);
  }
};

const createTimetableSlot = async (req, res, next) => {
  try {
    const { classId, section, dayOfWeek, startTime, endTime, subject, teacherId } = req.body;

    if (!classId || !dayOfWeek || !startTime || !endTime || !subject || !teacherId) {
      return res.status(400).json({ success: false, message: 'All slot fields are required.' });
    }

    // Check teacher collision at the same day/time
    const collision = await prisma.timetableSlot.findFirst({
      where: {
        academyId: req.academyId,
        teacherId,
        dayOfWeek,
        startTime
      }
    });

    if (collision) {
      return res.status(409).json({ success: false, message: 'Teacher is already scheduled for another class at this time slot.' });
    }

    const slot = await prisma.timetableSlot.create({
      data: {
        academyId: req.academyId,
        classId,
        section: section || 'A',
        dayOfWeek,
        startTime,
        endTime,
        subject,
        teacherId
      }
    });

    res.status(201).json({ success: true, message: 'Timetable slot created.', data: slot });
  } catch (err) {
    next(err);
  }
};

const deleteTimetableSlot = async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.timetableSlot.deleteMany({
      where: { id, academyId: req.academyId }
    });
    res.json({ success: true, message: 'Slot removed.' });
  } catch (err) {
    next(err);
  }
};

module.exports = { getTimetable, createTimetableSlot, deleteTimetableSlot };
