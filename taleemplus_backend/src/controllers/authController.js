const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../config/db');
const { validatePassword } = require('../utils/passwordPolicy');
const crypto = require('crypto');

const makeStudentCode = () => crypto.randomBytes(8).toString('hex');

const verifyPassword = async (req, res, next) => {
  try {
    const user = await prisma.user.findFirst({
      where: { id: req.user.id, academyId: req.academyId },
      select: { passwordHash: true },
    });
    const valid = Boolean(user && typeof req.body.password === 'string' &&
      await bcrypt.compare(req.body.password, user.passwordHash));
    return res.json({ success: true, data: { valid } });
  } catch (err) { next(err); }
};

const changePassword = async (req, res, next) => {
  try {
    if (typeof req.body.currentPassword !== 'string' || !req.body.currentPassword) {
      return res.status(400).json({ success: false, message: 'Current password is required.' });
    }
    const current = await prisma.user.findFirst({
      where: { id: req.user.id, academyId: req.academyId },
      select: { passwordHash: true },
    });
    if (!current || !(await bcrypt.compare(req.body.currentPassword, current.passwordHash))) {
      return res.status(403).json({ success: false, message: 'Current password is incorrect.' });
    }
    const passwordError = validatePassword(req.body.newPassword);
    if (passwordError) return res.status(400).json({ success: false, message: passwordError });
    if (req.body.currentPassword === req.body.newPassword) {
      return res.status(400).json({ success: false, message: 'Choose a password different from the current one.' });
    }
    const passwordHash = await bcrypt.hash(req.body.newPassword, 12);
    await prisma.user.update({
      where: { id: req.user.id },
      data: { passwordHash },
    });
    res.json({ success: true, message: 'Password updated successfully.' });
  } catch (err) { next(err); }
};

const updateAcademyProfile = async (req, res, next) => {
  try {
    const fields = [
      ['name', 'name', 120], ['address', 'address', 240],
      ['phone', 'phone', 40], ['logo', 'logo', 1000],
    ];
    const data = {};
    for (const [input, column, maxLength] of fields) {
      if (req.body[input] === undefined) continue;
      const value = req.body[input];
      if (value !== null && (typeof value !== 'string' || value.length > maxLength)) {
        return res.status(400).json({ success: false, message: `Invalid academy ${input}.` });
      }
      data[column] = typeof value === 'string' ? value.trim() || null : null;
    }
    if (!Object.keys(data).length) return res.status(400).json({ success: false, message: 'No academy profile fields provided.' });
    const academy = await prisma.academy.update({ where: { id: req.academyId }, data });
    res.json({ success: true, data: {
      academyName: academy.name, academyAddress: academy.address,
      academyPhone: academy.phone, academyLogo: academy.logo,
    } });
  } catch (err) { next(err); }
};

const JWT_SECRET = process.env.JWT_SECRET;
const REFRESH_SECRET = process.env.REFRESH_TOKEN_SECRET;

if (!JWT_SECRET || !REFRESH_SECRET) {
  throw new Error('JWT_SECRET and REFRESH_TOKEN_SECRET must be configured.');
}

const generateTokens = (userId, academyId, role) => {
  const accessToken = jwt.sign({ userId, academyId, role }, JWT_SECRET, { expiresIn: '15m' });
  const refreshToken = jwt.sign({ userId, academyId, role }, REFRESH_SECRET, { expiresIn: '7d' });
  return { accessToken, refreshToken };
};

const registerAdmin = async (req, res, next) => {
  try {
    const { email, password, fullName, academyName, academyAddress, academyPhone } = req.body;

    if (!email || !password || !fullName || !academyName) {
      return res.status(400).json({ success: false, message: 'Missing required registration fields.' });
    }
    const passwordError = validatePassword(password);
    if (passwordError) return res.status(400).json({ success: false, message: passwordError });

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Email address already registered.' });
    }

    const academyCode = 'TP-' + Math.random().toString(36).substring(2, 7).toUpperCase();
    const passwordHash = await bcrypt.hash(password, 10);

    const result = await prisma.$transaction(async (tx) => {
      const academy = await tx.academy.create({
        data: {
          code: academyCode,
          name: academyName,
          address: academyAddress || null,
          phone: academyPhone || null
        }
      });

      const user = await tx.user.create({
        data: {
          email,
          passwordHash,
          fullName,
          role: 'ADMIN',
          accountStatus: 'ACTIVE',
          academyId: academy.id
        }
      });

      return { academy, user };
    });

    const tokens = generateTokens(result.user.id, result.academy.id, result.user.role);
    await prisma.refreshToken.create({
      data: {
        userId: result.user.id,
        token: tokens.refreshToken,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      }
    });

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: result.user.id,
          email: result.user.email,
          fullName: result.user.fullName,
          role: result.user.role,
          accountStatus: result.user.accountStatus,
          academyId: result.user.academyId,
          academyCode: result.academy.code,
          academyName: result.academy.name,
          academyAddress: result.academy.address,
          academyPhone: result.academy.phone,
          academyLogo: result.academy.logo
        },
        tokens
      }
    });
  } catch (err) {
    next(err);
  }
};

const registerUser = async (req, res, next) => {
  try {
    const { email, password, fullName, role, academyCode, phoneNumber } = req.body;

    if (!email || !password || !fullName || !role || !academyCode) {
      return res.status(400).json({ success: false, message: 'Missing required registration fields.' });
    }
    const passwordError = validatePassword(password);
    if (passwordError) return res.status(400).json({ success: false, message: passwordError });

    const academy = await prisma.academy.findUnique({ where: { code: academyCode } });
    if (!academy) {
      return res.status(404).json({ success: false, message: 'Invalid academy code. Academy not found.' });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Email address already registered.' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const userRole = role.toUpperCase();

    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        fullName,
        phoneNumber: phoneNumber || null,
        role: userRole,
        accountStatus: 'PENDING',
        studentCode: userRole === 'STUDENT' ? makeStudentCode() : null,
        academyId: academy.id
      }
    });

    res.status(201).json({
      success: true,
      message: 'Account registered successfully. Pending Admin approval.',
      data: {
        user: {
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          role: user.role,
          accountStatus: user.accountStatus,
          academyId: user.academyId,
          academyName: academy.name,
          academyAddress: academy.address,
          academyPhone: academy.phone,
          academyLogo: academy.logo,
          studentCode: user.studentCode
        }
      }
    });
  } catch (err) {
    next(err);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password required.' });
    }

    const user = await prisma.user.findUnique({
      where: { email },
      include: { academy: true }
    });

    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials. Check email and password.' });
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid credentials. Check email and password.' });
    }

    if (user.accountStatus !== 'ACTIVE') {
      return res.status(403).json({
        success: false,
        message: `Account status is '${user.accountStatus}'. Please wait for Admin approval.`
      });
    }

    const tokens = generateTokens(user.id, user.academyId, user.role);

    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: tokens.refreshToken,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      }
    });

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          role: user.role,
          accountStatus: user.accountStatus,
          academyId: user.academyId,
          academyCode: user.academy.code,
          academyName: user.academy.name,
          academyAddress: user.academy.address,
          academyPhone: user.academy.phone,
          academyLogo: user.academy.logo,
          assignedSections: user.assignedSections,
          studentCode: user.studentCode
        },
        tokens
      }
    });
  } catch (err) {
    next(err);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken: token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: 'Refresh token required.' });
    }

    const savedToken = await prisma.refreshToken.findUnique({
      where: { token },
      include: { user: true }
    });

    if (!savedToken || savedToken.revoked || savedToken.expiresAt < new Date()) {
      return res.status(403).json({ success: false, message: 'Invalid or expired refresh token.' });
    }

    const decoded = jwt.verify(token, REFRESH_SECRET);
    const newTokens = generateTokens(decoded.userId, decoded.academyId, decoded.role);

    await prisma.refreshToken.update({
      where: { id: savedToken.id },
      data: { token: newTokens.refreshToken, expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) }
    });

    res.json({ success: true, data: newTokens });
  } catch (err) {
    return res.status(403).json({ success: false, message: 'Invalid refresh token.' });
  }
};

const logout = async (req, res, next) => {
  try {
    const { refreshToken: token } = req.body;
    if (token) {
      await prisma.refreshToken.updateMany({
        where: { token },
        data: { revoked: true }
      });
    }
    res.json({ success: true, message: 'Logged out successfully.' });
  } catch (err) {
    next(err);
  }
};

const getMe = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: {
        academy: true,
        parentLinks: { include: { student: true } },
        studentLinks: { include: { parent: true } }
      }
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found.' });
    }

    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        accountStatus: user.accountStatus,
        academyId: user.academyId,
        academyName: user.academy.name,
        academyAddress: user.academy.address,
        academyPhone: user.academy.phone,
        academyLogo: user.academy.logo,
        academyCode: user.academy.code,
        assignedSections: user.assignedSections,
        studentCode: user.studentCode,
        linkedChildren: user.parentLinks.map((link) => ({
          id: link.student.id,
          fullName: link.student.fullName,
          email: link.student.email
        }))
      }
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { registerAdmin, registerUser, login, refreshToken, logout, getMe, verifyPassword, changePassword, updateAcademyProfile };
