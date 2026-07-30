/// One student's mark on one quiz. Response-only shape — see
/// [MarkRecordInput] for what's sent when saving marks. The backend has no
/// denormalized `classId`/`month` on a mark (both are one join away via
/// `quiz`), so neither is carried here; nothing reads them.
class TestMarkModel {
  final String id;
  final String academyId;
  final String quizId;
  final String quizTitle;
  final String subject;
  final String studentId;
  final String studentName;
  final double marksObtained;
  final double totalMarks;
  final double percentage;
  final String gradeLetter;
  final String? teacherFeedback;
  final DateTime updatedAt;

  TestMarkModel({
    required this.id,
    required this.academyId,
    required this.quizId,
    required this.quizTitle,
    required this.subject,
    required this.studentId,
    required this.studentName,
    required this.marksObtained,
    required this.totalMarks,
    required this.percentage,
    required this.gradeLetter,
    this.teacherFeedback,
    required this.updatedAt,
  });

  static String calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  factory TestMarkModel.fromJson(Map<String, dynamic> json) {
    final quiz = json['quiz'] as Map<String, dynamic>;
    final student = json['student'] as Map<String, dynamic>;
    return TestMarkModel(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      quizId: quiz['id'] as String,
      quizTitle: quiz['title'] as String,
      subject: quiz['subject'] as String,
      studentId: student['id'] as String,
      studentName: student['fullName'] as String,
      marksObtained: (json['marksObtained'] as num).toDouble(),
      totalMarks: (json['totalMarks'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      gradeLetter: json['gradeLetter'] as String,
      teacherFeedback: json['teacherFeedback'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// One record in a `PUT /quizzes/:quizId/marks` upsert request.
class MarkRecordInput {
  final String studentId;
  final double marksObtained;
  final String? teacherFeedback;

  const MarkRecordInput(
      {required this.studentId,
      required this.marksObtained,
      this.teacherFeedback});

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'marksObtained': marksObtained,
        if (teacherFeedback != null && teacherFeedback!.isNotEmpty)
          'teacherFeedback': teacherFeedback,
      };
}
