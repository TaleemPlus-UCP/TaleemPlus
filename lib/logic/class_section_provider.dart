import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/models/class_section.dart';
import '../data/repositories/class_section_repository.dart';

/// Streams the academy's class+section rosters from Firestore in real time.
class ClassSectionProvider extends ChangeNotifier {
  final ClassSectionRepository _repo;
  ClassSectionProvider({ClassSectionRepository? repo})
      : _repo = repo ?? ClassSectionRepository();

  List<ClassSectionEntity> _sections = [];
  bool _loading = true;
  StreamSubscription? _sub;

  List<ClassSectionEntity> get sections => _sections;
  bool get loading => _loading;

  List<ClassSectionEntity> forClass(String className) =>
      _sections.where((s) => s.className == className).toList();

  /// Start streaming all class sections for a specific academy.
  void listenAll(String academyId) {
    _sub?.cancel();
    _loading = true;
    notifyListeners();
    _sub = _repo.watchAll(academyId).listen(
      (list) {
        _sections = list;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error listening to class sections: $e');
        _sections = [];
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> createSection({
    required String academyId,
    required String className,
    required String section,
  }) {
    return _repo.createSection(
      academyId: academyId,
      className: className,
      section: section,
    );
  }

  Future<void> updateEnrollment({
    required ClassSectionEntity section,
    required List<AppUser> students,
  }) {
    return _repo.updateEnrollment(section: section, students: students);
  }

  Future<void> deleteSection(ClassSectionEntity section) {
    return _repo.deleteSection(section);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
