import 'package:flutter/material.dart';
import '../data/models/fee_challan_model.dart';
import '../data/models/test_mark_model.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/fee_challan_repository.dart';
import '../data/remote/quiz_service.dart';
import 'fee_risk_model.dart';
import 'performance_index_model.dart';

class AdminAiProvider extends ChangeNotifier {
  final QuizService _quizService = QuizService();
  final FeeChallanRepository _feeRepo = FeeChallanRepository();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();

  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  // Insights Data
  int _atRiskCount = 0;
  String _weakestSubject = "No Data";
  double _academyAvgPerformance = 0.0;
  List<String> _atRiskStudentNames = [];

  // Revenue Forecasting
  double _projectedRevenue = 0.0;
  double _collectionEfficiency = 0.0;
  int _pendingPaymentsCount = 0;
  double _pendingAmount = 0.0;

  int get atRiskCount => _atRiskCount;
  String get weakestSubject => _weakestSubject;
  double get academyAvgPerformance => _academyAvgPerformance;
  List<String> get atRiskStudentNames => _atRiskStudentNames;

  double get projectedRevenue => _projectedRevenue;
  double get collectionEfficiency => _collectionEfficiency;
  int get pendingPaymentsCount => _pendingPaymentsCount;
  double get pendingAmount => _pendingAmount;

  // Fee-Delay Risk (trained logistic-regression model)
  int _feeRiskCount = 0;
  List<String> _feeRiskStudentNames = [];

  int get feeRiskCount => _feeRiskCount;
  List<String> get feeRiskStudentNames => _feeRiskStudentNames;

  // Performance Forecast (trained linear-regression model)
  double _predictedAvgPerformanceIndex = 0.0;
  List<String> _underperformingStudentNames = [];

  double get predictedAvgPerformanceIndex => _predictedAvgPerformanceIndex;
  List<String> get underperformingStudentNames => _underperformingStudentNames;

  Future<void> runAcademyAnalysis(String academyId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Run both analyses in parallel for THIS academy
      await Future.wait([
        _analyzePerformance(academyId),
        _analyzeRevenue(academyId),
        _analyzeFeeDelayRisk(academyId),
        _analyzePerformanceForecast(academyId),
      ]);
    } catch (e) {
      debugPrint("AI Analysis Error: $e");
      _error = 'Could not load insights: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _analyzePerformance(String academyId) async {
    final allMarks = await _quizService.getAllAcademyMarks(academyId);
    if (allMarks.isEmpty) {
      _atRiskCount = 0;
      _weakestSubject = "No Data";
      _academyAvgPerformance = 0.0;
      _atRiskStudentNames = [];
    } else {
      _calculatePerformanceInsights(allMarks);
    }
  }

  Future<void> _analyzeRevenue(String academyId) async {
    final allChallans = await _feeRepo.getAll(academyId);
    if (allChallans.isEmpty) {
      _projectedRevenue = 0;
      _collectionEfficiency = 0;
      _pendingPaymentsCount = 0;
      _pendingAmount = 0;
    } else {
      final totalPayable =
          allChallans.map((c) => c.totalAmount).reduce((a, b) => a + b);
      final totalPaid = allChallans
          .where((c) => c.isPaid)
          .map((c) => c.totalAmount)
          .fold(0.0, (a, b) => a + b);

      _pendingPaymentsCount = allChallans.where((c) => !c.isPaid).length;
      _pendingAmount = totalPayable - totalPaid;
      _collectionEfficiency = (totalPaid / totalPayable) * 100;
      _projectedRevenue =
          totalPayable; // Simple forecast: next month expected similar to current setup
    }
  }

  Future<void> _analyzeFeeDelayRisk(String academyId) async {
    final challans = await _feeRepo.getAll(academyId);
    if (challans.isEmpty) {
      _feeRiskCount = 0;
      _feeRiskStudentNames = [];
      return;
    }

    final attendanceRecords = await _attendanceRepo.getAllForAcademy(academyId);
    final Map<String, List<double>> attendedByStudent = {};
    for (final r in attendanceRecords) {
      final attended = (r.isPresent || r.isLate) ? 1.0 : 0.0;
      attendedByStudent.putIfAbsent(r.studentId, () => []).add(attended);
    }

    final Map<String, List<FeeChallanModel>> challansByStudent = {};
    for (final c in challans) {
      challansByStudent.putIfAbsent(c.studentId, () => []).add(c);
    }

    final atRisk = <String>[];
    challansByStudent.forEach((studentId, studentChallans) {
      final lateDays = studentChallans.map(_daysLate).toList();
      final daysLateAvg = lateDays.reduce((a, b) => a + b) / lateDays.length;
      final latePaymentCount = lateDays.where((d) => d > 0).length;

      final attendance = attendedByStudent[studentId];
      // No attendance history yet: give the benefit of the doubt rather
      // than flagging on payment history alone.
      final attendanceRate = (attendance == null || attendance.isEmpty)
          ? 1.0
          : attendance.reduce((a, b) => a + b) / attendance.length;

      final isAtRisk = FeeRiskModel.predictAtRisk(
        attendanceRate: attendanceRate,
        daysLateAvg: daysLateAvg,
        latePaymentCount: latePaymentCount,
      );

      if (isAtRisk) {
        atRisk.add(studentChallans.first.studentName);
      }
    });

    _feeRiskStudentNames = atRisk;
    _feeRiskCount = atRisk.length;
  }

  Future<void> _analyzePerformanceForecast(String academyId) async {
    final marks = await _quizService.getAllAcademyMarks(academyId);
    if (marks.isEmpty) {
      _predictedAvgPerformanceIndex = 0.0;
      _underperformingStudentNames = [];
      return;
    }

    final challans = await _feeRepo.getAll(academyId);
    final attendanceRecords = await _attendanceRepo.getAllForAcademy(academyId);

    final Map<String, List<double>> quizByStudent = {};
    final Map<String, String> studentNames = {};
    for (final m in marks) {
      quizByStudent.putIfAbsent(m.studentId, () => []).add(m.percentage);
      studentNames[m.studentId] = m.studentName;
    }

    final Map<String, List<double>> attendedByStudent = {};
    for (final r in attendanceRecords) {
      final attended = (r.isPresent || r.isLate) ? 1.0 : 0.0;
      attendedByStudent.putIfAbsent(r.studentId, () => []).add(attended);
    }

    final Map<String, List<FeeChallanModel>> challansByStudent = {};
    for (final c in challans) {
      challansByStudent.putIfAbsent(c.studentId, () => []).add(c);
    }

    final predictions = <double>[];
    final underperforming = <String>[];

    quizByStudent.forEach((studentId, scores) {
      final quizAvg = scores.reduce((a, b) => a + b) / scores.length;

      final attendance = attendedByStudent[studentId];
      final attendanceRate = (attendance == null || attendance.isEmpty)
          ? 1.0
          : attendance.reduce((a, b) => a + b) / attendance.length;

      final studentChallans = challansByStudent[studentId];
      final latePaymentCount =
          (studentChallans == null || studentChallans.isEmpty)
              ? 0
              : studentChallans.map(_daysLate).where((d) => d > 0).length;

      final predicted = PerformanceIndexModel.predict(
        quizAvg: quizAvg,
        attendanceRate: attendanceRate,
        latePaymentCount: latePaymentCount,
      );

      predictions.add(predicted);
      if (predicted < 50) {
        underperforming.add(studentNames[studentId]!);
      }
    });

    _predictedAvgPerformanceIndex =
        predictions.reduce((a, b) => a + b) / predictions.length;
    _underperformingStudentNames = underperforming;
  }

  double _daysLate(FeeChallanModel c) {
    final reference = c.isPaid ? c.updatedAt : DateTime.now();
    final diff = reference.difference(c.dueDate).inDays;
    return diff > 0 ? diff.toDouble() : 0.0;
  }

  void _calculatePerformanceInsights(List<TestMarkModel> marks) {
    // 1. Average Academy Performance
    _academyAvgPerformance =
        marks.map((m) => m.percentage).reduce((a, b) => a + b) / marks.length;

    // 2. Risk Analysis (Average Percentage < 50%)
    final Map<String, List<double>> studentScores = {};
    final Map<String, String> studentNames = {};

    for (var m in marks) {
      studentScores.putIfAbsent(m.studentId, () => []).add(m.percentage);
      studentNames[m.studentId] = m.studentName;
    }

    _atRiskStudentNames.clear();
    studentScores.forEach((id, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg < 50) {
        _atRiskStudentNames.add(studentNames[id]!);
      }
    });
    _atRiskCount = _atRiskStudentNames.length;

    // 3. Subject Weakness Analysis
    final Map<String, List<double>> subjectScores = {};
    for (var m in marks) {
      subjectScores.putIfAbsent(m.subject, () => []).add(m.percentage);
    }

    String weakest = "No Data";
    double lowestAvg = 101.0;

    subjectScores.forEach((sub, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg < lowestAvg) {
        lowestAvg = avg;
        weakest = sub;
      }
    });

    _weakestSubject = weakest;
  }
}
