import 'package:flutter/material.dart';
import '../data/models/test_mark_model.dart';
import '../data/repositories/fee_challan_repository.dart';
import '../data/remote/quiz_service.dart';

class AdminAiProvider extends ChangeNotifier {
  final QuizService _quizService = QuizService();
  final FeeChallanRepository _feeRepo = FeeChallanRepository();

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

  Future<void> runAcademyAnalysis(String academyId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Run both analyses in parallel for THIS academy
      await Future.wait([
        _analyzePerformance(academyId),
        _analyzeRevenue(academyId),
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
