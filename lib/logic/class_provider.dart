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

  int countFor(String classId) =>
      _classes
          .firstWhere(
            (c) => c.id == classId,
        orElse: () => ClassEntity(
            id: '', className: '', createdAt: DateTime.now()),
      )
          .enrollmentCount;

  /// Start streaming all classes (called by Admin screens).
  void listenAll() {
    _sub?.cancel();
    _loading = true;
    notifyListeners();
    _sub = _repo.watchAll().listen((list) {
      _classes = list;
      _loading = false;
      notifyListeners();
    });
  }

  Future<List<ClassEntity>> fetchForTeacherEmail(String email) {
    return _repo.watchForTeacherEmail(email).first;
  }

  Stream<List<ClassEntity>> streamForTeacherEmail(String email) =>
      _repo.watchForTeacherEmail(email);

  Future<void> createClassWithStudents({
    required String className,
    required String section,
    required String subject,
    required AppUser teacher,
    required List<AppUser> students,
  }) async {
    await _repo.createClass(
      className: className,
      section: section,
      subject: subject,
      teacher: teacher,
      students: students,
    );
  }

  Future<void> deleteClass(String classId) => _repo.deleteClass(classId);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}