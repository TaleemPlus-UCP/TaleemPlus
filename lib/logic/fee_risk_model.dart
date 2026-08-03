import 'dart:math';

/// On-device fee-delay risk predictor.
///
/// Weights are a scikit-learn LogisticRegression trained in
/// ml_training/train_risk_model.py on ml_training/data/synthetic_dataset.csv
/// (see ml_training/generate_synthetic_data.py for how that data was built),
/// ported here as a plain Dart dot-product + sigmoid instead of a
/// tflite_flutter/.tflite runtime dependency. Re-run those two scripts
/// against real academy data and paste the printed coefficients here to
/// retrain.
class FeeRiskModel {
  static const double _wAttendanceRate = -5.885984;
  static const double _wDaysLateAvg = 0.474142;
  static const double _wLatePaymentCount = 1.402795;
  static const double _intercept = 0.047898;

  /// Predicted probability (0-1) that a student's fee payment will be
  /// delayed, given:
  /// - [attendanceRate]: fraction of classes attended, 0-1
  /// - [daysLateAvg]: average days a payment was late across their challans
  /// - [latePaymentCount]: number of challans paid (or currently) late
  static double predictRiskProbability({
    required double attendanceRate,
    required double daysLateAvg,
    required int latePaymentCount,
  }) {
    final z = _intercept +
        _wAttendanceRate * attendanceRate +
        _wDaysLateAvg * daysLateAvg +
        _wLatePaymentCount * latePaymentCount;
    return 1 / (1 + exp(-z));
  }

  static bool predictAtRisk({
    required double attendanceRate,
    required double daysLateAvg,
    required int latePaymentCount,
  }) =>
      predictRiskProbability(
        attendanceRate: attendanceRate,
        daysLateAvg: daysLateAvg,
        latePaymentCount: latePaymentCount,
      ) >=
      0.5;
}
