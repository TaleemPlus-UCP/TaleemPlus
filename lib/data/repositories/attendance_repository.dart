import '../models/attendance_record.dart';
import '../remote/api_client.dart';

class AttendanceRepository {
  final ApiClient _api = ApiClient();

  Future<void> saveAll(List<AttendanceRecord> records) async {
    if (records.isEmpty) return;
    final first = records.first;
    final payload = {
      'classId': first.classId,
      'logDate': first.logDate,
      'records': records
          .map((r) => {
                'studentId': r.studentId,
                'status': r.status,
              })
          .toList(),
    };
    await _api.post('/attendance/mark', payload);
  }

  Future<List<AttendanceRecord>> forClassOnDate({
    required String classId,
    required DateTime date,
    required String academyId,
  }) async {
    try {
      final key = _dateOnly(date);
      final res =
          await _api.get('/attendance/class?classId=$classId&logDate=$key');
      final list = res as List;
      return list
          .map((item) => AttendanceRecord.fromMap(item['id'] ?? '', item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AttendanceRecord>> getAllForAcademy(String academyId) async {
    return [];
  }

  Stream<List<AttendanceRecord>> watchForStudent(
      String studentId, String academyId) async* {
    try {
      final res = await _api.get('/attendance/student/$studentId');
      final list = res as List;
      yield list
          .map((item) => AttendanceRecord.fromMap(item['id'] ?? '', item))
          .toList();
    } catch (_) {
      yield [];
    }
  }

  static String _dateOnly(DateTime d) {
    final iso = DateTime(d.year, d.month, d.day).toIso8601String();
    return iso.substring(0, 10);
  }
}
