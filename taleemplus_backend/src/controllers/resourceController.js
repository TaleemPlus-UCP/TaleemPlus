const prisma = require('../config/db');

const getResources = async (req, res, next) => {
  try {
    const { classId } = req.query;
    const whereClause = { academyId: req.academyId };
    if (classId) whereClause.classId = String(classId);

    const resources = await prisma.sharedResource.findMany({
      where: whereClause,
      include: { teacher: { select: { fullName: true } } },
      orderBy: { createdAt: 'desc' }
    });

    const formatted = resources.map((r) => ({
      id: r.id,
      academy_id: r.academyId,
      class_id: r.classId,
      teacher_id: r.teacherId,
      teacher_name: r.teacher.fullName,
      title: r.title,
      description: r.description || '',
      file_url: r.fileUrl,
      created_at: r.createdAt
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    next(err);
  }
};

const createResource = async (req, res, next) => {
  try {
    const { classId, title, description, fileUrl } = req.body;

    if (!classId || !title || !fileUrl) {
      return res.status(400).json({ success: false, message: 'classId, title, and fileUrl are required.' });
    }

    const resource = await prisma.sharedResource.create({
      data: {
        academyId: req.academyId,
        classId,
        teacherId: req.user.id,
        title,
        description: description || null,
        fileUrl
      }
    });

    res.status(201).json({ success: true, message: 'Resource published successfully.', data: resource });
  } catch (err) {
    next(err);
  }
};

const getQueries = async (req, res, next) => {
  try {
    const { classId } = req.query;
    const whereClause = { academyId: req.academyId };
    if (classId) whereClause.classId = String(classId);

    const queries = await prisma.studentQuery.findMany({
      where: whereClause,
      include: {
        student: { select: { fullName: true } },
        teacher: { select: { fullName: true } }
      },
      orderBy: { createdAt: 'desc' }
    });

    const formatted = queries.map((q) => ({
      id: q.id,
      academy_id: q.academyId,
      class_id: q.classId,
      student_id: q.studentId,
      student_name: q.student.fullName,
      teacher_id: q.teacherId,
      question: q.question,
      answer: q.answer || '',
      is_resolved: q.isResolved,
      created_at: q.createdAt,
      answered_at: q.answeredAt
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    next(err);
  }
};

const createQuery = async (req, res, next) => {
  try {
    const { classId, question } = req.body;

    if (!classId || !question) {
      return res.status(400).json({ success: false, message: 'classId and question are required.' });
    }

    const query = await prisma.studentQuery.create({
      data: {
        academyId: req.academyId,
        classId,
        studentId: req.user.id,
        question
      }
    });

    res.status(201).json({ success: true, message: 'Query submitted successfully.', data: query });
  } catch (err) {
    next(err);
  }
};

const answerQuery = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { answer } = req.body;

    if (!answer) {
      return res.status(400).json({ success: false, message: 'Answer text is required.' });
    }

    const updated = await prisma.studentQuery.update({
      where: { id },
      data: {
        teacherId: req.user.id,
        answer,
        isResolved: true,
        answeredAt: new Date()
      }
    });

    res.json({ success: true, message: 'Query answered successfully.', data: updated });
  } catch (err) {
    next(err);
  }
};

module.exports = { getResources, createResource, getQueries, createQuery, answerQuery };
