/// A student's question posted to their class offering's shared discussion
/// wall. `classId` is the offering id (same `offeringId` convention as
/// `QuizModel.classId`).
class StudentQuery {
  final String id;
  final String academyId;
  final String classId;
  final String studentId;
  final String studentName;
  final String teacherId;
  final String question;
  final String? answer;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime? answeredAt;

  StudentQuery({
    required this.id,
    required this.academyId,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.question,
    this.answer,
    this.isResolved = false,
    required this.createdAt,
    this.answeredAt,
  });

  factory StudentQuery.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    return StudentQuery(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      classId: json['offeringId'] as String,
      studentId: json['studentId'] as String,
      studentName: (student?['fullName'] as String?) ?? 'Student',
      teacherId: json['teacherId'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String?,
      isResolved: json['isResolved'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
    );
  }
}
