import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/class_entity.dart';

/// All class + enrollment persistence now lives in Firestore so every
/// device sees the same academy state.
class ClassRepository {
  final FirebaseFirestore _db;
  ClassRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('classes');

  // ---------- Reads ----------

  Stream<List<ClassEntity>> watchAll(String academyId) {
    // Removed orderBy from query to avoid index requirement.
    // Sorting is handled in the map function.
    return _col.where('academy_id', isEqualTo: academyId).snapshots().map(
      (snap) {
        final list =
            snap.docs.map((d) => ClassEntity.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  Stream<List<ClassEntity>> watchForTeacher(
      String teacherUid, String academyId) {
    return _col
        .where('academy_id', isEqualTo: academyId)
        .where('primary_teacher_id', isEqualTo: teacherUid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ClassEntity.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<ClassEntity?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ClassEntity.fromMap(doc.id, doc.data()!);
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
    final docRef = _col.doc();
    final entity = ClassEntity(
      id: docRef.id,
      academyId: academyId,
      className: className.trim(),
      section: section.trim(),
      subject: subject.trim(),
      primaryTeacherId: teacher.uid,
      primaryTeacherName: teacher.fullName,
      primaryTeacherEmail:
          teacher.email.trim().toLowerCase(), // LOWERCASE FOR CONSISTENCY
      studentIds: students.map((s) => s.uid).toList(),
      studentNames: {for (final s in students) s.uid: s.fullName},
      createdAt: DateTime.now(),
    );
    await docRef.set(entity.toMap());
    return docRef.id;
  }

  Future<void> deleteClass(String classId, String academyId) async {
    // Delete class doc
    await _col.doc(classId).delete();
    // Cascade delete attendance records for that class
    final att = await _db
        .collection('attendance_records')
        .where('academy_id', isEqualTo: academyId)
        .where('class_id', isEqualTo: classId)
        .get();
    for (final d in att.docs) {
      await d.reference.delete();
    }
  }

  /// Updates the list of students in an existing class.
  Future<void> updateClassEnrollment({
    required String classId,
    required List<AppUser> students,
  }) async {
    await _col.doc(classId).update({
      'student_ids': students.map((s) => s.uid).toList(),
      'student_names': {for (final s in students) s.uid: s.fullName},
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Updates class details including teacher and subject.
  Future<void> updateClassDetails({
    required String classId,
    String? className,
    String? section,
    String? subject,
    AppUser? teacher,
  }) async {
    final Map<String, dynamic> updates = {
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (className != null) updates['class_name'] = className.trim();
    if (section != null) updates['section'] = section.trim();
    if (subject != null) updates['subject'] = subject.trim();
    if (teacher != null) {
      updates['primary_teacher_id'] = teacher.uid;
      updates['primary_teacher_name'] = teacher.fullName;
      updates['primary_teacher_email'] = teacher.email;
    }
    await _col.doc(classId).update(updates);
  }

  /// Reassigns the primary teacher of a class. (Legacy support)
  Future<void> updateClassTeacher({
    required String classId,
    required AppUser teacher,
  }) async {
    await updateClassDetails(classId: classId, teacher: teacher);
  }
}
