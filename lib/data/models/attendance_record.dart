import 'package:cloud_firestore/cloud_firestore.dart';

/// One attendance record: a single student on a single date.
/// Stored in Firestore under `attendance_records/{docId}`.
class AttendanceRecord {
  final String id;
  final String academyId; // NEW
  final String classId;
  final String studentId;
  final String studentName;
  final DateTime logDate;
  final String status;      // 'present' | 'absent' | 'late'
  final String markedByUid;
  final DateTime recordedAt;

  const AttendanceRecord({
    required this.id,
    required this.academyId, // NEW
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.logDate,
    required this.status,
    required this.markedByUid,
    required this.recordedAt,
  });

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isLate => status == 'late';

  /// Deterministic Firestore doc id so that saving the same
  /// (class, student, date) upserts instead of duplicating.
  static String buildId({
    required String classId,
    required String studentId,
    required DateTime date,
  }) {
    final key = _dateOnly(date);
    return '${classId}_${studentId}_$key';
  }

  Map<String, dynamic> toMap() => {
    'academy_id': academyId,
    'class_id': classId,
    'student_id': studentId,
    'student_name': studentName,
    'log_date': _dateOnly(logDate),
    'status': status,
    'marked_by_uid': markedByUid,
    'recorded_at': FieldValue.serverTimestamp(),
  };

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['recorded_at'];
    return AttendanceRecord(
      id: id,
      academyId: (map['academy_id'] ?? '') as String,
      classId: (map['class_id'] ?? '') as String,
      studentId: (map['student_id'] ?? '') as String,
      studentName: (map['student_name'] ?? '') as String,
      logDate: DateTime.tryParse((map['log_date'] ?? '') as String) ??
          DateTime.now(),
      status: (map['status'] ?? 'absent') as String,
      markedByUid: (map['marked_by_uid'] ?? '') as String,
      recordedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  static String _dateOnly(DateTime d) {
    final iso = DateTime(d.year, d.month, d.day).toIso8601String();
    return iso.substring(0, 10);
  }
}