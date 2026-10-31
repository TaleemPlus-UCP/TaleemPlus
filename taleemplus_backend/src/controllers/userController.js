const bcrypt = require('bcryptjs');
const prisma = require('../config/db');

const getPendingUsers = async (req, res, next) => {
  try {
    const pendingUsers = await prisma.user.findMany({
      where: {
        academyId: req.academyId,
        accountStatus: 'PENDING'
      },
      select: {
        id: true,
        fullName: true,
        email: true,
        role: true,
        phoneNumber: true,
        accountStatus: true,
        createdAt: true
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ success: true, data: pendingUsers });
  } catch (err) {
    next(err);
  }
};

const approveUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await prisma.user.findFirst({
      where: { id, academyId: req.academyId }
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found in academy.' });
    }

    const updated = await prisma.user.update({
      where: { id },
      data: { accountStatus: 'ACTIVE' }
    });

    await prisma.notification.create({
      data: {
        academyId: req.academyId,
        recipientId: id,
        title: 'Account Approved',
        message: 'Your TaleemPlus account has been approved by the Admin.',
        type: 'approval'
      }
    });

    res.json({ success: true, message: 'User approved successfully.', data: updated });
  } catch (err) {
    next(err);
  }
};

const rejectUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await prisma.user.findFirst({
      where: { id, academyId: req.academyId }
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found in academy.' });
    }

    const updated = await prisma.user.update({
      where: { id },
      data: { accountStatus: 'REJECTED' }
    });

    res.json({ success: true, message: 'User rejected successfully.', data: updated });
  } catch (err) {
    next(err);
  }
};

const getUsersByRole = async (req, res, next) => {
  try {
    const { role } = req.query;
    const whereClause = {
      academyId: req.academyId,
      accountStatus: 'ACTIVE'
    };

    if (role) {
      whereClause.role = role.toUpperCase();
    }

    const users = await prisma.user.findMany({
      where: whereClause,
      select: {
        id: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        role: true,
        accountStatus: true,
        assignedSections: true,
        createdAt: true
      },
      orderBy: { fullName: 'asc' }
    });

    res.json({ success: true, data: users });
  } catch (err) {
    next(err);
  }
};

const linkChildToParent = async (req, res, next) => {
  try {
    const { parentId, studentId } = req.body;

    const parent = await prisma.user.findFirst({
      where: { id: parentId, academyId: req.academyId, role: 'PARENT' }
    });
    const student = await prisma.user.findFirst({
      where: { id: studentId, academyId: req.academyId, role: 'STUDENT' }
    });

    if (!parent || !student) {
      return res.status(404).json({ success: false, message: 'Parent or student not found in academy.' });
    }

    const link = await prisma.parentStudent.upsert({
      where: { parentId_studentId: { parentId, studentId } },
      create: { parentId, studentId },
      update: {}
    });

    res.json({ success: true, message: 'Student linked to parent successfully.', data: link });
  } catch (err) {
    next(err);
  }
};

const createUserByAdmin = async (req, res, next) => {
  try {
    const { email, password, fullName, role, phoneNumber, assignedSections } = req.body;

    if (!email || !password || !fullName || !role) {
      return res.status(400).json({ success: false, message: 'Missing required user fields.' });
    }

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(400).json({ success: false, message: 'User email already exists.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const newUser = await prisma.user.create({
      data: {
        email,
        passwordHash,
        fullName,
        phoneNumber: phoneNumber || null,
        role: role.toUpperCase(),
        accountStatus: 'ACTIVE',
        academyId: req.academyId,
        assignedSections: assignedSections || []
      }
    });

    res.status(201).json({ success: true, message: 'User created successfully.', data: newUser });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getPendingUsers,
  approveUser,
  rejectUser,
  getUsersByRole,
  linkChildToParent,
  createUserByAdmin
};
