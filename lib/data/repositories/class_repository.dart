import '../../core/constants/app_constants.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/api_exception.dart';
import '../../data/remote/auth_service.dart';
import '../models/app_user.dart';
import '../models/class_entity.dart';
import 'class_section_repository.dart';

/// Backed by the Node API's `/classes` (subject offerings) and
/// `/class-sections` endpoints instead of Firestore.
///
/// The backend normalizes what Firestore modeled as one flat "class" document
/// into two related resources: a [ClassSectionEntity] (e.g. "10th - A") that
/// owns the enrolled students, and a subject *offering* under it (e.g.
/// "10th - A / Physics / Mr. Khan") that owns the teacher and subject. A
/// [ClassEntity] here is the join of an offering with its section, so every
/// existing screen that reads `ClassEntity.studentIds`/`studentNames` keeps
/// working — but all offerings under the same section now necessarily share
/// one roster, matching the backend's already-accepted design (see
/// `backend/README.md`).
class ClassRepository {
  final ApiClient _api;
  final AuthService _authService;
  final ClassSectionRepository _sectionRepo;

  ClassRepository(
      {ApiClient? api,
      AuthService? authService,
      ClassSectionRepository? sectionRepo})
      : _api = api ?? ApiClient.instance,
        _authService = authService ?? AuthService(),
        _sectionRepo = sectionRepo ?? ClassSectionRepository();

  // ---------- Reads ----------

  Stream<List<ClassEntity>> watchAll(String academyId) {
    return Stream.fromFuture(_fetchAll(academyId));
  }

  Stream<List<ClassEntity>> watchForTeacher(
      String teacherUid, String academyId) {
    return Stream.fromFuture(_fetchAll(academyId, teacherUid: teacherUid));
  }

  Future<List<ClassEntity>> _fetchAll(String academyId,
      {String? teacherUid}) async {
    final offeringsResponse = await _api.get('/classes');
    final offeringsJson = offeringsResponse.data['data'] as List<dynamic>;

    final sections = await _sectionRepo.fetchAll();
    final studentIdsBySection = {for (final s in sections) s.id: s.studentIds};

    final students =
        await _authService.getApprovedByRole(UserRole.student, academyId);
    final namesByUid = {for (final s in students) s.uid: s.fullName};

    var list = offeringsJson
        .map((o) => _fromOfferingJson(
              o as Map<String, dynamic>,
              studentIdsBySection[
                      (o['section'] as Map<String, dynamic>)['id']] ??
                  const [],
              namesByUid,
            ))
        .toList();

    if (teacherUid != null) {
      list = list.where((c) => c.primaryTeacherId == teacherUid).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  ClassEntity _fromOfferingJson(
    Map<String, dynamic> json,
    List<String> sectionStudentIds,
    Map<String, String> namesByUid,
  ) {
    final section = json['section'] as Map<String, dynamic>;
    final teacher = json['teacher'] as Map<String, dynamic>?;
    return ClassEntity(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      sectionId: section['id'] as String,
      className: section['className'] as String,
      section: section['sectionLabel'] as String,
      subject: json['subject'] as String,
      primaryTeacherId: (teacher?['id'] as String?) ?? '',
      primaryTeacherName: (teacher?['fullName'] as String?) ?? '',
      primaryTeacherEmail: (teacher?['email'] as String?) ?? '',
      studentIds: sectionStudentIds,
      studentNames: {
        for (final uid in sectionStudentIds)
          if (namesByUid.containsKey(uid)) uid: namesByUid[uid]!,
      },
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Future<ClassEntity?> getById(String id) async {
    try {
      final response = await _api.get('/classes/$id');
      final json = response.data['data'] as Map<String, dynamic>;
      final sectionId =
          (json['section'] as Map<String, dynamic>)['id'] as String;
      final section = await _sectionRepo.fetchAll();
      final match = section.where((s) => s.id == sectionId);
      final sectionStudentIds =
          match.isEmpty ? <String>[] : match.first.studentIds;
      final students = await _authService.getApprovedByRole(
          UserRole.student, json['academyId'] as String);
      final namesByUid = {for (final s in students) s.uid: s.fullName};
      return _fromOfferingJson(json, sectionStudentIds, namesByUid);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ---------- Writes ----------

  Future<String> createClass({
    required String className,
    required String section,
    required String subject,
    required AppUser teacher,
    required List<AppUser> students,
    required String academyId,
  }) async {
    final trimmedClass = className.trim();
    final trimmedSection = section.trim();

    final existingSections = await _sectionRepo.fetchAll();
    final match = existingSections.where(
      (s) =>
          s.className.trim().toLowerCase() == trimmedClass.toLowerCase() &&
          s.section.trim().toLowerCase() == trimmedSection.toLowerCase(),
    );

    final String sectionId;
    if (match.isNotEmpty) {
      sectionId = match.first.id;
    } else {
      sectionId = await _sectionRepo.createSection(
        academyId: academyId,
        className: trimmedClass,
        section: trimmedSection,
      );
    }

    await _api.put('/class-sections/$sectionId/enrollment', data: {
      'studentIds': students.map((s) => s.uid).toList(),
    });

    final response = await _api.post('/classes', data: {
      'sectionId': sectionId,
      'teacherId': teacher.uid,
      'subject': subject.trim(),
    });
    return response.data['data']['id'] as String;
  }

  Future<void> deleteClass(String classId, String academyId) async {
    await _api.delete('/classes/$classId');
  }

  /// Updates the list of students in an existing class.
  ///
  /// Enrollment is owned by the class's *section*, not the subject offering
  /// itself (every offering under a section shares one roster) — so this
  /// resolves the offering's section first, then replaces that section's
  /// full roster. No screen currently calls this (see [ClassProvider]), but
  /// it is implemented fully rather than left as a stub.
  Future<void> updateClassEnrollment({
    required String classId,
    required List<AppUser> students,
  }) async {
    final response = await _api.get('/classes/$classId');
    final json = response.data['data'] as Map<String, dynamic>;
    final sectionId = (json['section'] as Map<String, dynamic>)['id'] as String;
    await _api.put('/class-sections/$sectionId/enrollment', data: {
      'studentIds': students.map((s) => s.uid).toList(),
    });
  }

  /// Updates class details including teacher and subject.
  ///
  /// [className]/[section] are not supported: the backend's offering
  /// endpoint only accepts `subject`/`teacherId` updates — a section's name
  /// is fixed at creation and has no rename endpoint (no screen exercises
  /// this; the one caller of [ClassProvider.updateClass] only ever passes
  /// `subject`/`teacher`). Passing them throws rather than silently
  /// discarding the request.
  Future<void> updateClassDetails({
    required String classId,
    String? className,
    String? section,
    String? subject,
    AppUser? teacher,
  }) async {
    if (className != null || section != null) {
      throw UnsupportedError(
        'Renaming a class\'s className/section is not supported by the backend — '
        'sections are named at creation only.',
      );
    }

    final body = <String, dynamic>{
      if (subject != null) 'subject': subject.trim(),
      if (teacher != null) 'teacherId': teacher.uid,
    };
    if (body.isEmpty) return;

    await _api.patch('/classes/$classId', data: body);
  }

  /// Reassigns the primary teacher of a class. (Legacy support)
  Future<void> updateClassTeacher({
    required String classId,
    required AppUser teacher,
  }) async {
    await updateClassDetails(classId: classId, teacher: teacher);
  }
}
