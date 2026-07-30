/// A subject offering — one class section's specific subject/teacher pairing,
/// e.g. "Class 10 - A (Physics)" taught by Mr. Khan.
class ClassEntity {
  final String id;
  final String academyId;
  final String sectionId;
  final String className;
  final String section;
  final String subject;
  final String primaryTeacherId; // teacher's uid
  final String primaryTeacherName;
  final String primaryTeacherEmail;
  final List<String> studentIds;
  final Map<String, String> studentNames;
  final DateTime createdAt;

  const ClassEntity({
    required this.id,
    required this.academyId,
    this.sectionId = '',
    required this.className,
    this.section = '',
    this.subject = '',
    this.primaryTeacherId = '',
    this.primaryTeacherName = '',
    this.primaryTeacherEmail = '',
    this.studentIds = const [],
    this.studentNames = const {},
    required this.createdAt,
  });

  int get enrollmentCount => studentIds.length;

  /// Display label like "Class 10 - A (Physics)"
  String get displayLabel {
    final buf = StringBuffer(className);
    if (section.isNotEmpty) buf.write(' - $section');
    if (subject.isNotEmpty) buf.write(' ($subject)');
    return buf.toString();
  }
}
