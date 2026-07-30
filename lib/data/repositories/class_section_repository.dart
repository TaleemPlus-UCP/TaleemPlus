import '../../data/remote/api_client.dart';
import '../models/app_user.dart';
import '../models/class_section.dart';

/// Backed by the Node API's `/class-sections` endpoints (see the backend's
/// Classes & Sections module) instead of Firestore.
///
/// `watchAll` is no longer a true real-time stream — the backend has no
/// push/live-update channel yet (Socket.IO wasn't built for this module).
/// It's a one-shot fetch wrapped in a single-emission [Stream] so every
/// existing `.listen(...)` call site (see [ClassSectionProvider.listenAll])
/// keeps compiling and working unchanged; screens just no longer see
/// another device's edits appear automatically, only after they reload.
///
/// [ClassSectionEntity.studentNames] is intentionally left empty here — no
/// screen actually reads it off a *section* (only off [ClassEntity], via
/// [ClassRepository]); the "Manage Enrollment" sheet only needs
/// `studentIds` to pre-check existing selections, and fetches the full
/// student list itself for display.
class ClassSectionRepository {
  final ApiClient _api;
  ClassSectionRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Stream<List<ClassSectionEntity>> watchAll(String academyId) {
    return Stream.fromFuture(fetchAll());
  }

  Future<List<ClassSectionEntity>> fetchAll() async {
    final response = await _api.get('/class-sections');
    final items = response.data['data'] as List<dynamic>;
    final list =
        items.map((s) => _fromJson(s as Map<String, dynamic>)).toList();
    list.sort((a, b) {
      final byClass = a.className.compareTo(b.className);
      return byClass != 0 ? byClass : a.section.compareTo(b.section);
    });
    return list;
  }

  ClassSectionEntity _fromJson(Map<String, dynamic> json) {
    return ClassSectionEntity(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      className: json['className'] as String,
      section: json['sectionLabel'] as String,
      studentIds: (json['studentIds'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Future<String> createSection({
    required String academyId,
    required String className,
    required String section,
  }) async {
    final response = await _api.post('/class-sections', data: {
      'className': className.trim(),
      'sectionLabel': section.trim(),
    });
    return response.data['data']['id'] as String;
  }

  Future<void> updateEnrollment({
    required ClassSectionEntity section,
    required List<AppUser> students,
  }) async {
    await _api.put('/class-sections/${section.id}/enrollment', data: {
      'studentIds': students.map((s) => s.uid).toList(),
    });
  }

  Future<void> deleteSection(ClassSectionEntity section) async {
    await _api.delete('/class-sections/${section.id}');
  }
}
