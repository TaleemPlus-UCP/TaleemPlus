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

  Stream<List<ClassEntity>> watchAll() {
    return _col.orderBy('created_at', descending: true).snapshots().map(
          (snap) => snap.docs
          .map((d) => ClassEntity.fromMap(d.id, d.data()))
          .toList(),
    );
  }

  Stream<List<ClassEntity>> watchForTeacherEmail(String email) {
    final e = email.trim().toLowerCase();
    return watchAll().map(
          (list) => list
          .where((c) => c.primaryTeacherEmail.toLowerCase() == e)
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
  }) async {
    final docRef = _col.doc();
    final entity = ClassEntity(
      id: docRef.id,
      className: className.trim(),
      section: section.trim(),
      subject: subject.trim(),
      primaryTeacherId: teacher.uid,
      primaryTeacherName: teacher.fullName,
      primaryTeacherEmail: teacher.email,
      studentIds: students.map((s) => s.uid).toList(),
      studentNames: {for (final s in students) s.uid: s.fullName},
      createdAt: DateTime.now(),
    );
    await docRef.set(entity.toMap());
    return docRef.id;
  }

  Future<void> deleteClass(String classId) async {
    // Delete class doc
    await _col.doc(classId).delete();
    // Cascade delete attendance records for that class
    final att = await _db
        .collection('attendance_records')
        .where('class_id', isEqualTo: classId)
        .get();
    for (final d in att.docs) {
      await d.reference.delete();
    }
  }
}