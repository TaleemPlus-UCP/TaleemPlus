const express = require('express');
const router = express.Router();
const resourceController = require('../controllers/resourceController');
const { authenticateToken } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

router.use(authenticateToken);

router.get('/resources', resourceController.getResources);
router.post('/resources', authorizeRoles('ADMIN', 'TEACHER'), resourceController.createResource);
router.get('/queries', resourceController.getQueries);
router.post('/queries', resourceController.createQuery);
router.put('/queries/:id/answer', authorizeRoles('ADMIN', 'TEACHER'), resourceController.answerQuery);

module.exports = router;
