import 'package:flutter/material.dart';
import '../data/remote/insights_service.dart';

class AdminAiProvider extends ChangeNotifier {
  final InsightsService _insightsService = InsightsService();

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
  double _pendingAmount = 0.0;

  int get atRiskCount => _atRiskCount;
  String get weakestSubject => _weakestSubject;
  double get academyAvgPerformance => _academyAvgPerformance;
  List<String> get atRiskStudentNames => _atRiskStudentNames;

  double get projectedRevenue => _projectedRevenue;
  double get collectionEfficiency => _collectionEfficiency;
  double get pendingAmount => _pendingAmount;

  /// `academyId` is unused — the backend scopes insights from the JWT —
  /// kept so call sites don't need to change.
  Future<void> runAcademyAnalysis(String academyId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final atRiskFuture = _insightsService.getAtRiskStudents();
      final revenueFuture = _insightsService.getRevenueForecast();
      final atRisk = await atRiskFuture;
      final revenue = await revenueFuture;

      _atRiskStudentNames = atRisk.students.map((s) => s.fullName).toList();
      _atRiskCount = atRisk.students.length;
      _academyAvgPerformance = atRisk.academyAveragePercentage;
      _weakestSubject = atRisk.weakestSubject ?? "No Data";

      _projectedRevenue = revenue.projectedRevenue;
      _collectionEfficiency = revenue.collectionEfficiency;
      _pendingAmount = revenue.pendingAmount;
    } catch (e) {
      debugPrint("AI Analysis Error: $e");
      _error = 'Could not load insights: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
