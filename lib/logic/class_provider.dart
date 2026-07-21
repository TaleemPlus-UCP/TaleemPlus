import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/models/class_entity.dart';
import '../data/repositories/class_repository.dart';

/// Streams the academy's classes from Firestore in real time.
class ClassProvider extends ChangeNotifier {
  final ClassRepository _repo;
  ClassProvider({ClassRepository? repo}) : _repo = repo ?? ClassRepository();

  List<ClassEntity> _classes = [];
  bool _loading = true;
  StreamSubscription? _sub;

  List<ClassEntity> get classes => _classes;
  bool get loading => _loading;

  int countFor(String classId) => _classes
      .firstWhere(
        (c) => c.id == classId,
        orElse: () => ClassEntity(
            id: '', className: '', academyId: '', createdAt: DateTime.now()),
      )
      .enrollmentCount;

  /// Start streaming all classes for a specific academy.
  void listenAll(String academyId) {
    _sub?.cancel();
    _loading = true;
    notifyListeners();
    _sub = _repo.watchAll(academyId).listen(
      (list) {
        _classes = list;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint("Error listening to classes: $e");
        _classes = [];
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<List<ClassEntity>> fetchForTeacher(
      String teacherUid, String academyId) {
    return _repo.watchForTeacher(teacherUid, academyId).first;
  }

  Stream<List<ClassEntity>> streamForTeacher(
          String teacherUid, String academyId) =>
      _repo.watchForTeacher(teacherUid, academyId);

  Future<void> createClassWithStudents({
    required String className,
    required String section,
    required String subject,
    required AppUser teacher,
    required List<AppUser> students,
    required String academyId, // NEW
  }) async {
    await _repo.createClass(
      className: className,
      section: section,
      subject: subject,
      teacher: teacher,
      students: students,
      academyId: academyId,
    );
  }

  Future<void> deleteClass(String classId) => _repo.deleteClass(classId);

  Future<void> updateEnrollment({
    required String classId,
    required List<AppUser> students,
  }) async {
    await _repo.updateClassEnrollment(classId: classId, students: students);
  }

  Future<void> updateClass({
    required String classId,
    String? className,
    String? section,
    String? subject,
    AppUser? teacher,
  }) async {
    await _repo.updateClassDetails(
      classId: classId,
      className: className,
      section: section,
      subject: subject,
      teacher: teacher,
    );
  }

  Future<void> updateTeacher({
    required String classId,
    required AppUser teacher,
  }) async {
    await updateClass(classId: classId, teacher: teacher);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
