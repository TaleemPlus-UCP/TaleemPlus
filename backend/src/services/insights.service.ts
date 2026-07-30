import { feeChallanRepository } from '../repositories/feeChallan.repository';
import { testMarkRepository } from '../repositories/testMark.repository';

const AT_RISK_THRESHOLD = 50;
const ON_TIME_PAYMENT_RATE = 0.85;

/**
 * Ported from prompt.md §5 ("Admin AI Insights") — a fixed-threshold
 * aggregation over existing data, not a trained model (see phases.md for
 * why the originally-planned TFLite classifier was de-scoped in favor of
 * this heuristic).
 */
async function getAtRiskStudents(academyId: string) {
  const marks = await testMarkRepository.findAllForAcademyWithQuiz(academyId);

  if (marks.length === 0) {
    return { students: [], academyAveragePercentage: 0, weakestSubject: null };
  }

  const byStudent = new Map<string, { fullName: string; sum: number; count: number }>();
  const bySubject = new Map<string, { sum: number; count: number }>();
  let academySum = 0;

  for (const mark of marks) {
    const percentage = mark.percentage.toNumber();
    academySum += percentage;

    const studentEntry = byStudent.get(mark.studentId) ?? { fullName: mark.student.fullName, sum: 0, count: 0 };
    studentEntry.sum += percentage;
    studentEntry.count += 1;
    byStudent.set(mark.studentId, studentEntry);

    const subjectEntry = bySubject.get(mark.quiz.subject) ?? { sum: 0, count: 0 };
    subjectEntry.sum += percentage;
    subjectEntry.count += 1;
    bySubject.set(mark.quiz.subject, subjectEntry);
  }

  const students = Array.from(byStudent.entries())
    .map(([studentId, { fullName, sum, count }]) => ({
      studentId,
      fullName,
      averagePercentage: Math.round((sum / count) * 100) / 100,
    }))
    .filter((s) => s.averagePercentage < AT_RISK_THRESHOLD)
    .sort((a, b) => a.averagePercentage - b.averagePercentage);

  let weakestSubject: { subject: string; averagePercentage: number } | null = null;
  for (const [subject, { sum, count }] of bySubject.entries()) {
    const average = sum / count;
    if (!weakestSubject || average < weakestSubject.averagePercentage) {
      weakestSubject = { subject, averagePercentage: Math.round(average * 100) / 100 };
    }
  }

  return {
    students,
    academyAveragePercentage: Math.round((academySum / marks.length) * 100) / 100,
    weakestSubject,
  };
}

async function getRevenueForecast(academyId: string) {
  const challans = await feeChallanRepository.findAllForAcademy(academyId);

  let totalPayable = 0;
  let totalPaid = 0;

  for (const challan of challans) {
    const total =
      challan.monthlyFee.toNumber() +
      challan.admissionFee.toNumber() +
      challan.examFee.toNumber() +
      challan.transportFee.toNumber() +
      challan.fine.toNumber();
    totalPayable += total;
    if (challan.status === 'PAID') totalPaid += total;
  }

  const round2 = (n: number) => Math.round(n * 100) / 100;
  const collectionEfficiency = totalPayable === 0 ? 0 : round2((totalPaid / totalPayable) * 100);
  const pendingAmount = round2(totalPayable - totalPaid);
  const projectedRevenue = round2(totalPayable);
  const predictedCollection = round2(projectedRevenue * ON_TIME_PAYMENT_RATE);

  return {
    totalPayable: round2(totalPayable),
    totalPaid: round2(totalPaid),
    collectionEfficiency,
    pendingAmount,
    projectedRevenue,
    predictedCollection,
  };
}

export const insightsService = {
  getAtRiskStudents,
  getRevenueForecast,
};
