const express = require('express');
const router = express.Router();
const feeController = require('../controllers/feeController');
const paymentController = require('../controllers/paymentController');
const { authenticateToken } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

router.use(authenticateToken);

router.get('/payment-settings', paymentController.getSettings);
router.put('/payment-settings', authorizeRoles('ADMIN'), paymentController.updateSettings);
router.post('/challans/:id/proof', authorizeRoles('STUDENT', 'PARENT'), paymentController.submitProof);
router.get('/payment-proofs/pending', authorizeRoles('ADMIN'), paymentController.listPendingProofs);
router.put('/payment-proofs/:id/review', authorizeRoles('ADMIN'), paymentController.reviewProof);

router.post('/challans/generate', authorizeRoles('ADMIN'), feeController.generateChallans);
router.post('/challans', authorizeRoles('ADMIN'), feeController.createStudentChallan);
router.get('/challans', authorizeRoles('ADMIN'), feeController.getAllChallans);
router.get('/challans/student/:studentId', feeController.getStudentChallans);
router.put('/challans/:id/pay', authorizeRoles('ADMIN'), feeController.markChallanPaid);
router.get('/ledger/stats', authorizeRoles('ADMIN'), feeController.getFeeLedgerStats);

module.exports = router;
