const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const { authenticateToken } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

router.use(authenticateToken);

router.post('/mark', authorizeRoles('ADMIN', 'TEACHER'), attendanceController.markAttendance);
router.get('/student/:studentId', attendanceController.getStudentAttendance);
router.get('/class', authorizeRoles('ADMIN', 'TEACHER'), attendanceController.getClassAttendance);

module.exports = router;
