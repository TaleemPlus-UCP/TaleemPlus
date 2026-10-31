const prisma = require('../config/db');

const getQuizzes = async (req, res, next) => {
  try {
    const { classId } = req.query;

    const whereClause = { academyId: req.academyId };
    if (classId) whereClause.classId = String(classId);

    const quizzes = await prisma.quiz.findMany({
      where: whereClause,
      include: { questions: true },
      orderBy: { createdAt: 'desc' }
    });

    const formatted = quizzes.map((q) => ({
      id: q.id,
      academy_id: q.academyId,
      class_id: q.classId,
      class_label: q.classLabel,
      title: q.title,
      subject: q.subject,
      month: q.month || '',
      session: q.session || '',
      chapter: q.chapter || '',
      difficulty: q.difficulty || '',
      total_marks: q.totalMarks,
      created_by_uid: q.createdById,
      created_at: q.createdAt,
      questions: q.questions.map((quest) => ({
        id: quest.id,
        text: quest.text,
        type: quest.type,
        options: quest.options,
        correct_index: quest.correctIndex,
        marks: quest.marks,
        grading_keywords: quest.gradingKeywords
      }))
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    next(err);
  }
};

const createQuiz = async (req, res, next) => {
  try {
    const { classId, classLabel, title, subject, totalMarks, questions, instructions } = req.body;

    if (!classId || !title || !subject || !totalMarks || !questions) {
      return res.status(400).json({ success: false, message: 'Missing required quiz fields.' });
    }

    const quiz = await prisma.quiz.create({
      data: {
        academyId: req.academyId,
        classId,
        classLabel: classLabel || subject,
        title,
        subject,
        totalMarks: parseInt(totalMarks),
        instructions: instructions || null,
        createdById: req.user.id,
        questions: {
          create: questions.map((q) => ({
            text: q.text,
            type: q.type || 'short',
            options: q.options || [],
            correctIndex: q.correct_index != null ? q.correct_index : null,
            marks: q.marks || 5,
            gradingKeywords: q.grading_keywords || []
          }))
        }
      },
      include: { questions: true }
    });

    res.status(201).json({ success: true, message: 'Quiz created successfully.', data: quiz });
  } catch (err) {
    next(err);
  }
};

const calculateGrade = (percentage) => {
  if (percentage >= 90) return 'A+';
  if (percentage >= 80) return 'A';
  if (percentage >= 70) return 'B';
  if (percentage >= 60) return 'C';
  if (percentage >= 50) return 'D';
  return 'F';
};

const upsertTestMark = async (req, res, next) => {
  try {
    const { quizId, studentId, marksObtained, teacherFeedback } = req.body;

    if (!quizId || !studentId || marksObtained == null) {
      return res.status(400).json({ success: false, message: 'quizId, studentId, and marksObtained are required.' });
    }

    const quiz = await prisma.quiz.findFirst({
      where: { id: quizId, academyId: req.academyId }
    });

    const student = await prisma.user.findFirst({
      where: { id: studentId, academyId: req.academyId }
    });

    if (!quiz || !student) {
      return res.status(404).json({ success: false, message: 'Quiz or student not found in academy.' });
    }

    const total = quiz.totalMarks;
    const obtained = parseFloat(marksObtained);
    const percentage = total > 0 ? (obtained / total) * 100 : 0;
    const gradeLetter = calculateGrade(percentage);

    const testMark = await prisma.testMark.upsert({
      where: { quizId_studentId: { quizId, studentId } },
      create: {
        academyId: req.academyId,
        quizId,
        studentId,
        studentName: student.fullName,
        classId: quiz.classId,
        subject: quiz.subject,
        month: quiz.month || null,
        marksObtained: obtained,
        totalMarks: total,
        percentage,
        gradeLetter,
        teacherFeedback: teacherFeedback || null
      },
      update: {
        marksObtained: obtained,
        totalMarks: total,
        percentage,
        gradeLetter,
        teacherFeedback: teacherFeedback || null,
        updatedAt: new Date()
      }
    });

    res.json({ success: true, message: 'Test mark saved successfully.', data: testMark });
  } catch (err) {
    next(err);
  }
};

const getStudentMarks = async (req, res, next) => {
  try {
    const { studentId } = req.params;

    const marks = await prisma.testMark.findMany({
      where: {
        academyId: req.academyId,
        studentId
      },
      include: { quiz: true },
      orderBy: { updatedAt: 'desc' }
    });

    const formatted = marks.map((m) => ({
      id: m.id,
      academy_id: m.academyId,
      quiz_id: m.quizId,
      student_id: m.studentId,
      student_name: m.studentName,
      class_id: m.classId,
      subject: m.subject,
      month: m.month || '',
      marks_obtained: m.marksObtained,
      total_marks: m.totalMarks,
      percentage: m.percentage,
      grade_letter: m.gradeLetter,
      teacher_feedback: m.teacherFeedback || '',
      updated_at: m.updatedAt
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    next(err);
  }
};

module.exports = { getQuizzes, createQuiz, upsertTestMark, getStudentMarks };
