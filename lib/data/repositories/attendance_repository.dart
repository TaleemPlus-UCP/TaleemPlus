import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_record.dart';

class AttendanceRepository {
  final FirebaseFirestore _db;
  AttendanceRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('attendance_records');

  /// Save (upsert) many records atomically using a Firestore WriteBatch.
  /// Deterministic doc ids ensure re-saves overwrite the same day's data.
  Future<void> saveAll(List<AttendanceRecord> records) async {
    if (records.isEmpty) return;
    final batch = _db.batch();
    for (final r in records) {
      final docId = AttendanceRecord.buildId(
        classId: r.classId,
        studentId: r.studentId,
        date: r.logDate,
      );
      batch.set(_col.doc(docId), r.toMap());
    }
    await batch.commit();
  }

  /// Fetch all records for a class on a given date (one-time).
  Future<List<AttendanceRecord>> forClassOnDate({
    required String classId,
    required DateTime date,
  }) async {
    final key = _dateOnly(date);
    final snap = await _col
        .where('class_id', isEqualTo: classId)
        .where('log_date', isEqualTo: key)
        .get();
    return snap.docs
        .map((d) => AttendanceRecord.fromMap(d.id, d.data()))
        .toList();
  }

  static String _dateOnly(DateTime d) {
    final iso = DateTime(d.year, d.month, d.day).toIso8601String();
    return iso.substring(0, 10);
  }
}