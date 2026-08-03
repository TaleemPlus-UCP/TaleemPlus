import 'package:flutter_test/flutter_test.dart';
import 'package:taleemplus_app/logic/fee_risk_model.dart';

void main() {
  group('FeeRiskModel', () {
    test('good attendance and on-time payments predicts low risk', () {
      final prob = FeeRiskModel.predictRiskProbability(
        attendanceRate: 0.95,
        daysLateAvg: 0,
        latePaymentCount: 0,
      );
      expect(prob, lessThan(0.5));
      expect(
        FeeRiskModel.predictAtRisk(
          attendanceRate: 0.95,
          daysLateAvg: 0,
          latePaymentCount: 0,
        ),
        isFalse,
      );
    });

    test('poor attendance and repeated late payments predicts high risk', () {
      final prob = FeeRiskModel.predictRiskProbability(
        attendanceRate: 0.4,
        daysLateAvg: 15,
        latePaymentCount: 4,
      );
      expect(prob, greaterThan(0.5));
      expect(
        FeeRiskModel.predictAtRisk(
          attendanceRate: 0.4,
          daysLateAvg: 15,
          latePaymentCount: 4,
        ),
        isTrue,
      );
    });

    test('risk probability increases as attendance drops, all else equal',
        () {
      final higherAttendance = FeeRiskModel.predictRiskProbability(
        attendanceRate: 0.9,
        daysLateAvg: 5,
        latePaymentCount: 1,
      );
      final lowerAttendance = FeeRiskModel.predictRiskProbability(
        attendanceRate: 0.5,
        daysLateAvg: 5,
        latePaymentCount: 1,
      );
      expect(lowerAttendance, greaterThan(higherAttendance));
    });
  });
}
