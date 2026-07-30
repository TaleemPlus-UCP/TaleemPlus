import '../../data/remote/api_client.dart';
import '../models/attendance_record.dart';

/// Backed by the Node API's `/attendance` endpoints instead of Firestore.
///
/// Attendance is tracked per subject *offering* (each teacher marks their
/// own class), but a student's monthly/yearly history is a cross-offering
/// rollup for the whole academy — the backend has no per-offering history
/// query, only a day sheet for marking and month/year summaries for
/// viewing. See [AttendanceProvider] and the screens under
/// `features/student/screens` and `features/parent/screens` for how each
/// is used.
class AttendanceRepository {
  final ApiClient _api;
  AttendanceRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  /// One class offering's attendance sheet for one day: studentId -> status
  /// (lowercased), defaulted to 'absent' for every enrolled student unless
  /// already marked.
  Future<Map<String, String>> getDaySheet({
    required String offeringId,
    required DateTime logDate,
  }) async {
    final response = await _api.get('/attendance', queryParameters: {
      'offeringId': offeringId,
      'logDate': _dateOnly(logDate),
    });
    final students = (response.data['data'] as Map<String, dynamic>)['students']
        as List<dynamic>;
    return {
      for (final s in students)
        (s as Map<String, dynamic>)['studentId'] as String:
            (s['status'] as String).toLowerCase(),
    };
  }

  /// Upserts a full day's attendance sheet for a class offering.
  Future<void> markSheet({
    required String offeringId,
    required DateTime logDate,
    required Map<String, String> statuses,
  }) async {
    await _api.post('/attendance', data: {
      'offeringId': offeringId,
      'logDate': _dateOnly(logDate),
      'records': statuses.entries
          .map((e) => {'studentId': e.key, 'status': e.value.toUpperCase()})
          .toList(),
    });
  }

  /// One student's daily records + summary for a month (defaults to the
  /// current month server-side when [year]/[month] are omitted).
  Future<AttendanceMonthlyReport> getStudentMonthly(String studentId,
      {int? year, int? month}) async {
    final response = await _api
        .get('/attendance/students/$studentId/monthly', queryParameters: {
      if (year != null) 'year': year,
      if (month != null) 'month': month,
    });
    return AttendanceMonthlyReport.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// One student's month-by-month summary for a year (defaults to the
  /// current year server-side when [year] is omitted).
  Future<AttendanceYearlyReport> getStudentYearly(String studentId,
      {int? year}) async {
    final response = await _api
        .get('/attendance/students/$studentId/yearly', queryParameters: {
      if (year != null) 'year': year,
    });
    return AttendanceYearlyReport.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  static String _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);
}
