/// On-device performance-index predictor.
///
/// Weights are a scikit-learn LinearRegression trained in
/// ml_training/train_risk_model.py on ml_training/data/synthetic_dataset.csv,
/// ported here as a plain Dart dot-product instead of a tflite_flutter/
/// .tflite runtime dependency. Re-run that script against real academy data
/// and paste the printed coefficients here to retrain. See
/// [FeeRiskModel] for the sibling fee-delay-risk model.
class PerformanceIndexModel {
  static const double _wQuizAvg = 0.565978;
  static const double _wAttendanceRate = 41.762108;
  static const double _wLatePaymentCount = -2.955087;
  static const double _intercept = 1.193829;

  /// Predicted performance index (0-100) given:
  /// - [quizAvg]: student's average quiz percentage, 0-100
  /// - [attendanceRate]: fraction of classes attended, 0-1
  /// - [latePaymentCount]: number of fee challans paid (or currently) late
  static double predict({
    required double quizAvg,
    required double attendanceRate,
    required int latePaymentCount,
  }) {
    final value = _intercept +
        _wQuizAvg * quizAvg +
        _wAttendanceRate * attendanceRate +
        _wLatePaymentCount * latePaymentCount;
    return value.clamp(0, 100);
  }
}
