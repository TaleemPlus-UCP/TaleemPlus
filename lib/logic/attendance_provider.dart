import 'package:flutter/foundation.dart';

import '../data/models/attendance_record.dart';
import '../data/models/class_entity.dart';
import '../data/repositories/attendance_repository.dart';

/// Manages the in-progress attendance sheet for one class + date.
/// Data source is Firestore, so all devices see the same result.
class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repo;
  AttendanceProvider({AttendanceRepository? repo})
      : _repo = repo ?? AttendanceRepository();

  /// Map<studentUid, 'present'|'absent'|'late'>.
  final Map<String, String> _statuses = {};

  bool _loading = false;
  bool _saving = false;
  String? _lastError;

  Map<String, String> get statuses => _statuses;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get lastError => _lastError;

  String statusFor(String studentId) => _statuses[studentId] ?? 'absent';

  int get presentCount =>
      _statuses.values.where((s) => s == 'present').length;
  int get absentCount => _statuses.values.where((s) => s == 'absent').length;
  int get lateCount => _statuses.values.where((s) => s == 'late').length;

  void setStatus(String studentId, String status) {
    _statuses[studentId] = status;
    notifyListeners();
  }

  void markAll(String status, List<String> studentIds) {
    for (final id in studentIds) {
      _statuses[id] = status;
    }
    notifyListeners();
  }

  /// Load existing sheet (if any) so the teacher can edit it.
  /// `allStudentIds` should be the enrolled uids from the class doc.
  Future<void> loadForClassDate({
    required String classId,
    required DateTime date,
    required List<String> allStudentIds,
  }) async {
    _loading = true;
    _lastError = null;
    _statuses.clear();
    notifyListeners();

    for (final id in allStudentIds) {
      _statuses[id] = 'absent'; // default
    }
    try {
      final existing =
      await _repo.forClassOnDate(classId: classId, date: date);
      for (final r in existing) {
        _statuses[r.studentId] = r.status;
      }
    } catch (_) {
      _lastError = 'Could not load previous attendance.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> save({
    required ClassEntity classEntity,
    required DateTime date,
    required String markedByUid,
  }) async {
    _saving = true;
    _lastError = null;
    notifyListeners();
    try {
      final records = <AttendanceRecord>[];
      final now = DateTime.now();
      _statuses.forEach((studentId, status) {
        records.add(AttendanceRecord(
          id: AttendanceRecord.buildId(
              classId: classEntity.id, studentId: studentId, date: date),
          classId: classEntity.id,
          studentId: studentId,
          studentName: classEntity.studentNames[studentId] ?? '',
          logDate: date,
          status: status,
          markedByUid: markedByUid,
          recordedAt: now,
        ));
      });
      await _repo.saveAll(records);
      _saving = false;
      notifyListeners();
      return true;
    } catch (_) {
      _saving = false;
      _lastError = 'Could not save attendance. Check your connection.';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _statuses.clear();
    _loading = false;
    _saving = false;
    _lastError = null;
    notifyListeners();
  }
}