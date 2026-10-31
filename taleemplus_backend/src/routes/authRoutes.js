const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateToken } = require('../middleware/authMiddleware');

router.post('/register-admin', authController.registerAdmin);
router.post('/register-user', authController.registerUser);
router.post('/login', authController.login);
router.post('/refresh', authController.refreshToken);
router.post('/logout', authController.logout);
router.get('/me', authenticateToken, authController.getMe);

module.exports = router;
