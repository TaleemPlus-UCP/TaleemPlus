const { buildFeeFeatures, buildPerformanceFeatures } = require('../src/services/mlFeatureService');

describe('academy-scoped ML feature engineering', () => {
  it('calculates fee history only from paid records already known at prediction time', () => {
    const now = new Date('2026-10-31T00:00:00Z');
    const rows = buildFeeFeatures(['student-a'], [
      { studentId: 'student-a', status: 'PAID', paidAt: new Date('2026-09-10'), dueDate: new Date('2026-09-01'), totalAmount: 100 },
      { studentId: 'student-a', status: 'PAID', paidAt: new Date('2026-11-10'), dueDate: new Date('2026-11-01'), totalAmount: 200 },
      { studentId: 'student-a', status: 'PENDING', paidAt: null, dueDate: new Date('2026-10-01'), totalAmount: 300 },
    ], [
      { studentId: 'student-a', status: 'PRESENT' },
      { studentId: 'student-a', status: 'ABSENT' },
    ], now);

    expect(rows.get('student-a')).toMatchObject({
      attendance_pct: 50, late_count: 1, delay_avg: 9, consistency: 0, outstanding: 500,
    });
  });

  it('keeps performance features grouped by student and subject without IDs in features', () => {
    const rows = buildPerformanceFeatures([
      { studentId: 'student-a', subject: 'Science', percentage: 80 },
      { studentId: 'student-a', subject: 'Science', percentage: 60 },
      { studentId: 'student-a', subject: 'Math', percentage: 90 },
    ], [{ studentId: 'student-a', status: 'LATE' }, { studentId: 'student-a', status: 'ABSENT' }]);
    const science = rows.find((row) => row.subject === 'Science');
    expect(science.features).toEqual({ prior_avg: 70, prior_count: 2, attendance_pct: 50 });
    expect(science.features).not.toHaveProperty('studentId');
  });
});
