const express = require('express');
const router = express.Router();
const feeController = require('../controllers/feeController');
const { authenticateToken } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

router.use(authenticateToken);

router.post('/challans/generate', authorizeRoles('ADMIN'), feeController.generateChallans);
router.get('/challans/student/:studentId', feeController.getStudentChallans);
router.put('/challans/:id/pay', authorizeRoles('ADMIN'), feeController.markChallanPaid);
router.get('/ledger/stats', authorizeRoles('ADMIN'), feeController.getFeeLedgerStats);

module.exports = router;
