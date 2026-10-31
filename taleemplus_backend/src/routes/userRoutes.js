const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

router.use(authenticateToken);

router.get('/pending', authorizeRoles('ADMIN'), userController.getPendingUsers);
router.put('/:id/approve', authorizeRoles('ADMIN'), userController.approveUser);
router.put('/:id/reject', authorizeRoles('ADMIN'), userController.rejectUser);
router.get('/by-role', userController.getUsersByRole);
router.post('/link-child', authorizeRoles('ADMIN', 'PARENT'), userController.linkChildToParent);
router.post('/create', authorizeRoles('ADMIN'), userController.createUserByAdmin);

module.exports = router;
