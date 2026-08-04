import '../data/models/class_section.dart';
import '../data/models/fee_challan_model.dart';

/// Per-class+section fee summary — paid/pending/overdue counts and amounts,
/// plus a collection percentage. Shared by the Fee Ledger's analytics view
/// and the Class Reports snapshot feature, so the aggregation logic lives
/// in exactly one place.
class ClassFeeAnalytics {
  final String classLabel;
  final int totalStudents;
  final int paidCount;
  final int pendingCount;
  final int overdueCount;
  final double paidAmount;
  final double pendingAmount;
  final double overdueAmount;

  const ClassFeeAnalytics({
    required this.classLabel,
    required this.totalStudents,
    required this.paidCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.overdueAmount,
  });

  int get challanCount => paidCount + pendingCount + overdueCount;
  double get collectionPercent =>
      totalStudents == 0 ? 0 : (paidCount / totalStudents) * 100;
}

class FeeAnalyticsService {
  FeeAnalyticsService._();

  /// Groups [challans] by their `classLabel` (already a flattened
  /// "ClassName - Section" string, same value [ClassSectionEntity.displayLabel]
  /// produces at challan-generation time) and cross-references student
  /// counts against the real class+section rosters in [sections] — a class
  /// might have more enrolled students than generated challans, so student
  /// count intentionally comes from the roster, not from challan rows.
  static List<ClassFeeAnalytics> computeClassAnalytics(
    List<FeeChallanModel> challans,
    List<ClassSectionEntity> sections,
  ) {
    final byClass = <String, List<FeeChallanModel>>{};
    for (final c in challans) {
      byClass.putIfAbsent(c.classLabel, () => []).add(c);
    }
    final rosterByLabel = {
      for (final s in sections) s.displayLabel: s.enrollmentCount,
    };
    final labels = {...byClass.keys, ...rosterByLabel.keys};

    final result = labels.map((label) {
      final list = byClass[label] ?? const <FeeChallanModel>[];
      final paid = list.where((c) => c.isPaid).toList();
      final overdue = list.where((c) => c.isOverdue).toList();
      final pending = list.where((c) => !c.isPaid && !c.isOverdue).toList();

      double sumOf(List<FeeChallanModel> l) =>
          l.fold(0.0, (sum, c) => sum + c.totalAmount);

      return ClassFeeAnalytics(
        classLabel: label,
        totalStudents:
            rosterByLabel[label] ?? list.map((c) => c.studentId).toSet().length,
        paidCount: paid.length,
        pendingCount: pending.length,
        overdueCount: overdue.length,
        paidAmount: sumOf(paid),
        pendingAmount: sumOf(pending),
        overdueAmount: sumOf(overdue),
      );
    }).toList();

    result.sort((a, b) => a.classLabel.compareTo(b.classLabel));
    return result;
  }
}
