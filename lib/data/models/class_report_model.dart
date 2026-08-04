import 'package:cloud_firestore/cloud_firestore.dart';

/// A point-in-time snapshot of one class+section's attendance and fee
/// standing, generated on demand by an admin and kept until deleted.
class ClassReportModel {
  final String id;
  final String academyId;
  final String classLabel;
  final DateTime generatedAt;
  final int totalStudents;
  final int present;
  final int absent;
  final int feePaid;
  final int feePending;
  final double feePaidAmount;
  final double feePendingAmount;

  const ClassReportModel({
    required this.id,
    required this.academyId,
    required this.classLabel,
    required this.generatedAt,
    required this.totalStudents,
    required this.present,
    required this.absent,
    required this.feePaid,
    required this.feePending,
    required this.feePaidAmount,
    required this.feePendingAmount,
  });

  Map<String, dynamic> toMap() => {
        'academy_id': academyId,
        'class_label': classLabel,
        'generated_at': Timestamp.fromDate(generatedAt),
        'total_students': totalStudents,
        'present': present,
        'absent': absent,
        'fee_paid': feePaid,
        'fee_pending': feePending,
        'fee_paid_amount': feePaidAmount,
        'fee_pending_amount': feePendingAmount,
      };

  factory ClassReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ClassReportModel(
      id: id,
      academyId: (map['academy_id'] ?? '') as String,
      classLabel: (map['class_label'] ?? '') as String,
      generatedAt: map['generated_at'] is Timestamp
          ? (map['generated_at'] as Timestamp).toDate()
          : DateTime.now(),
      totalStudents: (map['total_students'] ?? 0) as int,
      present: (map['present'] ?? 0) as int,
      absent: (map['absent'] ?? 0) as int,
      feePaid: (map['fee_paid'] ?? 0) as int,
      feePending: (map['fee_pending'] ?? 0) as int,
      feePaidAmount: (map['fee_paid_amount'] ?? 0).toDouble(),
      feePendingAmount: (map['fee_pending_amount'] ?? 0).toDouble(),
    );
  }
}
