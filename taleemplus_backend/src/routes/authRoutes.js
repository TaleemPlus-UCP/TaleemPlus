const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateToken } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

router.post('/register-admin', authController.registerAdmin);
router.post('/register-user', authController.registerUser);
router.post('/login', authController.login);
router.post('/refresh', authController.refreshToken);
router.post('/logout', authController.logout);
router.get('/me', authenticateToken, authController.getMe);
router.post('/verify-password', authenticateToken, authController.verifyPassword);
router.put('/password', authenticateToken, authController.changePassword);
router.put('/academy', authenticateToken, authorizeRoles('ADMIN'), authController.updateAcademyProfile);

module.exports = router;
