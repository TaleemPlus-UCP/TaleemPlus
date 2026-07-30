import { Router } from 'express';
import * as controller from '../controllers/insights.controller';
import { authenticate } from '../middlewares/authenticate';
import { requireActiveAccount, requireRoles } from '../middlewares/authorize';

export const insightsRouter = Router();

insightsRouter.use(authenticate, requireActiveAccount, requireRoles('ADMIN'));

/**
 * @openapi
 * /insights/at-risk-students:
 *   get:
 *     summary: At-risk student prediction — students averaging below 50% across all their test marks, plus academy average and weakest subject (fixed-threshold heuristic, not a trained model — see prompt.md)
 *     tags: [Insights]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: "{ students: [{studentId, fullName, averagePercentage}], academyAveragePercentage, weakestSubject }" }
 */
insightsRouter.get('/at-risk-students', controller.atRiskStudents);

/**
 * @openapi
 * /insights/revenue-forecast:
 *   get:
 *     summary: Fee collection efficiency and a naive next-month revenue projection (fixed 85% on-time-payment discount — see prompt.md)
 *     tags: [Insights]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: "{ totalPayable, totalPaid, collectionEfficiency, pendingAmount, projectedRevenue, predictedCollection }" }
 */
insightsRouter.get('/revenue-forecast', controller.revenueForecast);
