const prisma = require('../config/db');
const crypto = require('crypto');
const { canReadStudent } = require('../utils/studentAccess');

const createStudentChallan = async (req, res, next) => {
  try {
    const { studentId, classLabel, rollNumber, dueDate } = req.body;
    const student = await prisma.user.findFirst({
      where: { id: studentId, academyId: req.academyId, role: 'STUDENT' },
      select: { id: true, fullName: true, studentCode: true }
    });
    if (!student) return res.status(404).json({ success: false, message: 'Student not found in this academy.' });
    const parsedDueDate = new Date(dueDate);
    if (!dueDate || Number.isNaN(parsedDueDate.getTime())) {
      return res.status(400).json({ success: false, message: 'A valid dueDate is required.' });
    }
    const billingPeriod = req.body.billingPeriod || `${parsedDueDate.getUTCFullYear()}-${String(parsedDueDate.getUTCMonth() + 1).padStart(2, '0')}`;
    if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(billingPeriod)) {
      return res.status(400).json({ success: false, message: 'billingPeriod must use YYYY-MM format.' });
    }
    const existing = await prisma.feeChallan.findFirst({
      where: { academyId: req.academyId, studentId: student.id, billingPeriod },
      select: { id: true },
    });
    if (existing) return res.status(409).json({ success: false, message: 'A challan already exists for this student and billing period.' });
    const amounts = ['monthlyFee', 'admissionFee', 'examFee', 'transportFee', 'fine'];
    const values = {};
    for (const field of amounts) {
      const value = Number(req.body[field] || 0);
      if (!Number.isFinite(value) || value < 0) {
        return res.status(400).json({ success: false, message: `Invalid ${field}.` });
      }
      values[field] = value;
    }
    const challan = await prisma.feeChallan.create({
      data: {
        academyId: req.academyId,
        challanNumber: `CH-${crypto.randomBytes(6).toString('hex').toUpperCase()}`,
        studentId: student.id,
        studentName: student.fullName,
        classLabel: String(classLabel || '—').slice(0, 120),
        rollNumber: rollNumber ? String(rollNumber).slice(0, 40) : null,
        dueDate: parsedDueDate,
        billingPeriod,
        ...values,
        totalAmount: Object.values(values).reduce((sum, amount) => sum + amount, 0),
      },
      include: { student: { select: { studentCode: true } } }
    });
    res.status(201).json({ success: true, data: { ...challan, student_code: challan.student.studentCode } });
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ success: false, message: 'A challan already exists for this student and billing period.' });
    next(err);
  }
};

const getAllChallans = async (req, res, next) => {
  try {
    const rows = await prisma.feeChallan.findMany({
      where: { academyId: req.academyId },
      include: { student: { select: { studentCode: true } } },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, data: rows.map((c) => ({
      id: c.id, academy_id: c.academyId, challan_number: c.challanNumber,
      student_id: c.studentId, student_code: c.student.studentCode || c.studentId,
      student_name: c.studentName, father_name: c.fatherName || '',
      billing_period: c.billingPeriod,
      class_label: c.classLabel, roll_number: c.rollNumber || '',
      issue_date: c.issueDate, due_date: c.dueDate,
      monthly_fee: Number(c.monthlyFee), admission_fee: Number(c.admissionFee),
      exam_fee: Number(c.examFee), transport_fee: Number(c.transportFee), fine: Number(c.fine),
      total_amount: Number(c.totalAmount), status: c.status.toLowerCase(), created_at: c.createdAt,
    })) });
  } catch (err) { next(err); }
};

const generateChallans = async (req, res, next) => {
  try {
    const { classId, monthlyFee, admissionFee, examFee, transportFee, fine, dueDate } = req.body;

    if (!classId || !monthlyFee || !dueDate) {
      return res.status(400).json({ success: false, message: 'classId, monthlyFee, and dueDate are required.' });
    }

    const classObj = await prisma.class.findFirst({
      where: { id: classId, academyId: req.academyId },
      include: { enrollments: { include: { student: true } } }
    });

    if (!classObj) {
      return res.status(404).json({ success: false, message: 'Class section not found.' });
    }

    const classLabel = `${classObj.className} - ${classObj.section}`;
    const mFee = parseFloat(monthlyFee) || 0;
    const aFee = parseFloat(admissionFee) || 0;
    const eFee = parseFloat(examFee) || 0;
    const tFee = parseFloat(transportFee) || 0;
    const fFee = parseFloat(fine) || 0;
    const totalAmount = mFee + aFee + eFee + tFee + fFee;
    const parsedDueDate = new Date(dueDate);

    const createdChallans = [];
    for (const enrollment of classObj.enrollments) {
      const challanNumber = 'CH-' + Math.floor(100000 + Math.random() * 900000);
      const challan = await prisma.feeChallan.create({
        data: {
          academyId: req.academyId,
          challanNumber,
          studentId: enrollment.studentId,
          studentName: enrollment.student.fullName,
          classLabel,
          rollNumber: enrollment.rollNumber || null,
          dueDate: parsedDueDate,
          monthlyFee: mFee,
          admissionFee: aFee,
          examFee: eFee,
          transportFee: tFee,
          fine: fFee,
          totalAmount,
          status: 'PENDING'
        }
      });
      createdChallans.push(challan);
    }

    res.status(201).json({
      success: true,
      message: `Generated ${createdChallans.length} fee challans successfully.`,
      data: createdChallans
    });
  } catch (err) {
    next(err);
  }
};

const getStudentChallans = async (req, res, next) => {
  try {
    const { studentId } = req.params;
    if (!(await canReadStudent(req, studentId))) {
      return res.status(403).json({ success: false, message: 'You cannot access this student’s fee records.' });
    }

    const challans = await prisma.feeChallan.findMany({
      where: {
        academyId: req.academyId,
        studentId
      },
      include: { student: { select: { studentCode: true } } },
      orderBy: { createdAt: 'desc' }
    });

    const formatted = challans.map((c) => ({
      id: c.id,
      academy_id: c.academyId,
      challan_number: c.challanNumber,
      student_id: c.studentId,
      student_code: c.student.studentCode || c.studentId,
      billing_period: c.billingPeriod,
      student_name: c.studentName,
      father_name: c.fatherName || '',
      class_label: c.classLabel,
      roll_number: c.rollNumber || '',
      issue_date: c.issueDate,
      due_date: c.dueDate,
      monthly_fee: Number(c.monthlyFee),
      admission_fee: Number(c.admissionFee),
      exam_fee: Number(c.examFee),
      transport_fee: Number(c.transportFee),
      fine: Number(c.fine),
      total_amount: Number(c.totalAmount),
      status: c.status.toLowerCase(),
      created_at: c.createdAt
    }));

    res.json({ success: true, data: formatted });
  } catch (err) {
    next(err);
  }
};

const markChallanPaid = async (req, res, next) => {
  try {
    const { id } = req.params;

    const existing = await prisma.feeChallan.findFirst({
      where: { id, academyId: req.academyId }
    });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Fee challan not found.' });
    }

    const updated = await prisma.feeChallan.update({
      where: { id },
      data: { status: 'PAID', paidAt: existing.paidAt || new Date() }
    });

    res.json({ success: true, message: 'Fee challan marked as PAID.', data: updated });
  } catch (err) {
    next(err);
  }
};

const getFeeLedgerStats = async (req, res, next) => {
  try {
    const challans = await prisma.feeChallan.findMany({
      where: { academyId: req.academyId }
    });

    let totalBilled = 0;
    let totalCollected = 0;
    let pendingCount = 0;
    let paidCount = 0;
    let overdueCount = 0;

    for (const c of challans) {
      const amount = Number(c.totalAmount);
      totalBilled += amount;
      if (c.status === 'PAID') {
        totalCollected += amount;
        paidCount++;
      } else if (c.status === 'OVERDUE') {
        overdueCount++;
      } else {
        pendingCount++;
      }
    }

    const collectionPercentage = totalBilled > 0 ? ((totalCollected / totalBilled) * 100).toFixed(1) : 0;

    res.json({
      success: true,
      data: {
        total_billed: totalBilled,
        total_collected: totalCollected,
        total_pending: totalBilled - totalCollected,
        collection_percentage: Number(collectionPercentage),
        paid_count: paidCount,
        pending_count: pendingCount,
        overdue_count: overdueCount
      }
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { generateChallans, createStudentChallan, getAllChallans, getStudentChallans, markChallanPaid, getFeeLedgerStats };
