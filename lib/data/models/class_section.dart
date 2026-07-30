import 'package:cloud_firestore/cloud_firestore.dart';

/// A class + section (e.g. "10th - A") is the single enrollment unit,
/// stored under the `class_sections` collection.
///
/// Students are enrolled here exactly once. Every subject offering (see
/// [ClassEntity] in `classes`) that shares the same academy_id + class_name
/// + section mirrors this roster instead of keeping its own independent
/// copy, so admins never re-enroll the same section per subject.
class ClassSectionEntity {
  final String id;
  final String academyId;
  final String className;
  final String section;
  final List<String> studentIds;
  final Map<String, String> studentNames;
  final DateTime createdAt;

  const ClassSectionEntity({
    required this.id,
    required this.academyId,
    required this.className,
    required this.section,
    this.studentIds = const [],
    this.studentNames = const {},
    required this.createdAt,
  });

  int get enrollmentCount => studentIds.length;

  /// Display label like "10th - A".
  String get displayLabel =>
      section.isEmpty ? className : '$className - $section';

  Map<String, dynamic> toMap() => {
        'academy_id': academyId,
        'class_name': className,
        'section': section,
        'student_ids': studentIds,
        'student_names': studentNames,
        'created_at': createdAt.millisecondsSinceEpoch == 0
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt),
        'updated_at': FieldValue.serverTimestamp(),
      };

  factory ClassSectionEntity.fromMap(String id, Map<String, dynamic> map) {
    final rawIds = map['student_ids'];
    final rawNames = map['student_names'];
    final ts = map['created_at'];
    return ClassSectionEntity(
      id: id,
      academyId: (map['academy_id'] ?? '') as String,
      className: (map['class_name'] ?? '') as String,
      section: (map['section'] ?? '') as String,
      studentIds: (rawIds is List) ? rawIds.cast<String>() : const [],
      studentNames: (rawNames is Map)
          ? rawNames.map((k, v) => MapEntry(k as String, v as String))
          : const {},
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
