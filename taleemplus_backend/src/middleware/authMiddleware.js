const jwt = require('jsonwebtoken');
const prisma = require('../config/db');

const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access token required.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      include: { academy: true }
    });

    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid session user.' });
    }

    if (user.accountStatus !== 'ACTIVE') {
      return res.status(403).json({ success: false, message: 'Account is pending approval or disabled.' });
    }

    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
      academyId: user.academyId,
      fullName: user.fullName,
      assignedSections: user.assignedSections
    };

    req.academyId = user.academyId;
    next();
  } catch (err) {
    return res.status(403).json({ success: false, message: 'Token expired or invalid.' });
  }
};

module.exports = { authenticateToken };
