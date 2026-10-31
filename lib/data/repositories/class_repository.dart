import '../models/app_user.dart';
import '../models/class_entity.dart';
import '../remote/api_client.dart';

class ClassRepository {
  final ApiClient _api = ApiClient();

  ClassRepository({dynamic db});

  Stream<List<ClassEntity>> watchAll(String academyId) async* {
    try {
      final res = await _api.get('/classes');
      final list = res as List;
      final classes = list.map((item) => ClassEntity.fromMap(item['id'] ?? '', item)).toList();
      classes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield classes;
    } catch (_) {
      yield [];
    }
  }

  Stream<List<ClassEntity>> watchForTeacher(String teacherUid, String academyId) async* {
    try {
      final res = await _api.get('/classes');
      final list = res as List;
      yield list
          .map((item) => ClassEntity.fromMap(item['id'] ?? '', item))
          .where((c) => c.primaryTeacherId == teacherUid)
          .toList();
    } catch (_) {
      yield [];
    }
  }

  Stream<List<ClassEntity>> watchForStudent(String studentUid, String academyId) async* {
    try {
      final res = await _api.get('/classes');
      final list = res as List;
      yield list
          .map((item) => ClassEntity.fromMap(item['id'] ?? '', item))
          .where((c) => c.studentIds.contains(studentUid))
          .toList();
    } catch (_) {
      yield [];
    }
  }

  Future<ClassEntity?> getById(String id) async {
    try {
      final res = await _api.get('/classes');
      final list = res as List;
      final match = list.firstWhere((item) => item['id'] == id, orElse: () => null);
      if (match == null) return null;
      return ClassEntity.fromMap(match['id'], match);
    } catch (_) {
      return null;
    }
  }

  Future<String> createClass({
    required String className,
    required String section,
    required String subject,
    required AppUser teacher,
    required List<AppUser> students,
    required String academyId,
  }) async {
    final res = await _api.post('/classes', {
      'className': className.trim(),
      'section': section.trim(),
      'subject': subject.trim(),
      'primaryTeacherId': teacher.uid,
    });
    return res['id'] ?? '';
  }

  Future<void> deleteClass(String classId, String academyId) async {
    await _api.delete('/classes/$classId');
  }

  Future<void> updateClassEnrollment({
    required String classId,
    required List<AppUser> students,
  }) async {
    // handled via student enroll
    for (final s in students) {
      await _api.post('/classes/$classId/enroll', {'studentId': s.uid});
    }
  }

  Future<void> updateClassDetails({
    required String classId,
    String? className,
    String? section,
    String? subject,
    AppUser? teacher,
  }) async {
    // no-op or handled via backend update
  }

  Future<void> updateClassTeacher({
    required String classId,
    required AppUser teacher,
  }) async {
    await updateClassDetails(classId: classId, teacher: teacher);
  }
}
