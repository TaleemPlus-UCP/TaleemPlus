const express = require('express');
const router = express.Router();
const quizController = require('../controllers/quizController');
const { authenticateToken } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

router.use(authenticateToken);

router.get('/', quizController.getQuizzes);
router.post('/', authorizeRoles('ADMIN', 'TEACHER'), quizController.createQuiz);
router.post('/marks', authorizeRoles('ADMIN', 'TEACHER'), quizController.upsertTestMark);
router.get('/marks/student/:studentId', quizController.getStudentMarks);

module.exports = router;
