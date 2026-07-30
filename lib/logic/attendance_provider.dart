import 'package:flutter/foundation.dart';

import '../data/models/attendance_record.dart';
import '../data/models/class_entity.dart';
import '../data/repositories/attendance_repository.dart';

/// Manages the in-progress attendance sheet for one class + date, plus
/// on-demand monthly/yearly history lookups for a single student.
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

  int get presentCount => _statuses.values.where((s) => s == 'present').length;
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
  /// `academyId` is no longer needed to scope the request (the backend
  /// infers it from the JWT) but is kept so the call site is unchanged.
  Future<void> loadForClassDate({
    required String classId,
    required DateTime date,
    required List<String> allStudentIds,
    required String academyId,
  }) async {
    _loading = true;
    _lastError = null;
    _statuses.clear();
    notifyListeners();

    for (final id in allStudentIds) {
      _statuses[id] = 'absent'; // default
    }
    try {
      final daySheet =
          await _repo.getDaySheet(offeringId: classId, logDate: date);
      daySheet.forEach((studentId, status) {
        if (allStudentIds.contains(studentId)) _statuses[studentId] = status;
      });
    } catch (_) {
      _lastError = 'Could not load previous attendance.';
    }
    _loading = false;
    notifyListeners();
  }

  /// `markedByUid` is no longer needed (the backend attributes the sheet to
  /// the authenticated user) but is kept so the call site is unchanged.
  Future<bool> save({
    required ClassEntity classEntity,
    required DateTime date,
    required String markedByUid,
  }) async {
    _saving = true;
    _lastError = null;
    notifyListeners();
    try {
      await _repo.markSheet(
          offeringId: classEntity.id, logDate: date, statuses: _statuses);
      _saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _saving = false;
      _lastError = 'Could not save attendance: $e';
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

  /// One student's daily records + summary for a month (current month if
  /// omitted).
  Future<AttendanceMonthlyReport> loadStudentMonthly(String studentId,
      {int? year, int? month}) {
    return _repo.getStudentMonthly(studentId, year: year, month: month);
  }

  /// One student's month-by-month summary for a year (current year if
  /// omitted).
  Future<AttendanceYearlyReport> loadStudentYearly(String studentId,
      {int? year}) {
    return _repo.getStudentYearly(studentId, year: year);
  }
}
