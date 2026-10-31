const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticateToken } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

router.use(authenticateToken);

router.get('/notifications', notificationController.getNotifications);
router.put('/notifications/:id/read', notificationController.markNotificationRead);
router.get('/announcements', notificationController.getAnnouncements);
router.post('/announcements', authorizeRoles('ADMIN', 'TEACHER'), notificationController.createAnnouncement);

module.exports = router;
