import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/class_section.dart';
import 'class_repository.dart';

/// Owns the canonical class+section roster (`class_sections` collection).
///
/// Subject offerings in `classes` (see [ClassRepository]) mirror this
/// roster rather than keeping their own copy, so enrolling a student
/// happens exactly once per section regardless of how many subjects or
/// teachers are assigned to it.
class ClassSectionRepository {
  final FirebaseFirestore _db;
  final ClassRepository _classRepo;
  ClassSectionRepository({FirebaseFirestore? db, ClassRepository? classRepo})
      : _db = db ?? FirebaseFirestore.instance,
        _classRepo = classRepo ?? ClassRepository(db: db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('class_sections');

  // ---------- Reads ----------

  Stream<List<ClassSectionEntity>> watchAll(String academyId) {
    return _col.where('academy_id', isEqualTo: academyId).snapshots().map(
      (snap) {
        final list = snap.docs
            .map((d) => ClassSectionEntity.fromMap(d.id, d.data()))
            .toList();
        list.sort((a, b) {
          final byClass = a.className.compareTo(b.className);
          return byClass != 0 ? byClass : a.section.compareTo(b.section);
        });
        return list;
      },
    );
  }

  // ---------- Writes ----------

  Future<String> createSection({
    required String academyId,
    required String className,
    required String section,
  }) async {
    final docRef = _col.doc();
    final entity = ClassSectionEntity(
      id: docRef.id,
      academyId: academyId,
      className: className.trim(),
      section: section.trim(),
      createdAt: DateTime.now(),
    );
    await docRef.set(entity.toMap());
    return docRef.id;
  }

  /// Updates the section's roster and cascades it to every subject
  /// offering under the same academy/class/section, so a single
  /// enrollment edit keeps every `classes` document in sync.
  Future<void> updateEnrollment({
    required ClassSectionEntity section,
    required List<AppUser> students,
  }) async {
    final studentIds = students.map((s) => s.uid).toList();
    final studentNames = {for (final s in students) s.uid: s.fullName};

    await _col.doc(section.id).update({
      'student_ids': studentIds,
      'student_names': studentNames,
      'updated_at': FieldValue.serverTimestamp(),
    });

    final offerings = await _offeringsFor(section);

    const chunkSize = 450;
    final docs = offerings.docs;
    for (var i = 0; i < docs.length; i += chunkSize) {
      final end = i + chunkSize > docs.length ? docs.length : i + chunkSize;
      final batch = _db.batch();
      for (final doc in docs.sublist(i, end)) {
        batch.update(doc.reference, {
          'student_ids': studentIds,
          'student_names': studentNames,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  /// Deletes the section and cascades: every subject offering under it
  /// (and their attendance/timetable records, via
  /// [ClassRepository.deleteClass]) is removed too, since a subject
  /// offering can't exist without its section.
  Future<void> deleteSection(ClassSectionEntity section) async {
    final offerings = await _offeringsFor(section);
    for (final doc in offerings.docs) {
      await _classRepo.deleteClass(doc.id, section.academyId);
    }
    await _col.doc(section.id).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _offeringsFor(
      ClassSectionEntity section) {
    return _db
        .collection('classes')
        .where('academy_id', isEqualTo: section.academyId)
        .where('class_name', isEqualTo: section.className)
        .where('section', isEqualTo: section.section)
        .get();
  }
}
