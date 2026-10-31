const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../config/db');

const JWT_SECRET = process.env.JWT_SECRET || 'taleemplus_super_secret_jwt_key_2026';
const REFRESH_SECRET = process.env.REFRESH_TOKEN_SECRET || 'taleemplus_refresh_token_secret_2026';

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
          academyName: result.academy.name
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
          academyId: user.academyId
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
          assignedSections: user.assignedSections
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
        academyCode: user.academy.code,
        assignedSections: user.assignedSections,
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

module.exports = { registerAdmin, registerUser, login, refreshToken, logout, getMe };
