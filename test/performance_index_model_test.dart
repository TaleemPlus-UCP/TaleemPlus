import 'package:flutter_test/flutter_test.dart';
import 'package:taleemplus_app/logic/performance_index_model.dart';

void main() {
  group('PerformanceIndexModel', () {
    test('strong quiz scores and attendance predict a high index', () {
      final predicted = PerformanceIndexModel.predict(
        quizAvg: 90,
        attendanceRate: 0.95,
        latePaymentCount: 0,
      );
      expect(predicted, greaterThan(70));
    });

    test('weak quiz scores and attendance predict a low index', () {
      final predicted = PerformanceIndexModel.predict(
        quizAvg: 30,
        attendanceRate: 0.4,
        latePaymentCount: 3,
      );
      expect(predicted, lessThan(50));
    });

    test('result is always clamped to the 0-100 range', () {
      final high = PerformanceIndexModel.predict(
        quizAvg: 100,
        attendanceRate: 1.0,
        latePaymentCount: 0,
      );
      final low = PerformanceIndexModel.predict(
        quizAvg: 0,
        attendanceRate: 0.0,
        latePaymentCount: 12,
      );
      expect(high, lessThanOrEqualTo(100));
      expect(low, greaterThanOrEqualTo(0));
    });

    test('index increases with quiz average, all else equal', () {
      final lower = PerformanceIndexModel.predict(
        quizAvg: 40,
        attendanceRate: 0.8,
        latePaymentCount: 1,
      );
      final higher = PerformanceIndexModel.predict(
        quizAvg: 80,
        attendanceRate: 0.8,
        latePaymentCount: 1,
      );
      expect(higher, greaterThan(lower));
    });
  });
}
