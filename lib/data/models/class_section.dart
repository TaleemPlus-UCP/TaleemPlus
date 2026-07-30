/// A class + section (e.g. "10th - A") is the single enrollment unit.
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
}
