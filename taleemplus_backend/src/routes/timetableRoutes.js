const express = require('express');
const router = express.Router();
const timetableController = require('../controllers/timetableController');
const { authenticateToken } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

router.use(authenticateToken);

router.get('/', timetableController.getTimetable);
router.post('/', authorizeRoles('ADMIN'), timetableController.createTimetableSlot);
router.delete('/:id', authorizeRoles('ADMIN'), timetableController.deleteTimetableSlot);

module.exports = router;
