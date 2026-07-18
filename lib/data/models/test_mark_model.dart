import 'package:cloud_firestore/cloud_firestore.dart';

class TestMarkModel {
  final String id; // {quizId}_{studentUid}
  final String academyId; // NEW
  final String quizId;
  final String studentId;
  final String studentName;
  final String classId;
  final String subject;   // NEW: Denormalized for AI
  final String month;     // NEW: Denormalized for AI
  final double marksObtained;
  final double totalMarks;
  final double percentage;
  final String gradeLetter;
  final String? teacherFeedback;
  final DateTime updatedAt;

  TestMarkModel({
    required this.id,
    required this.academyId, // NEW
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.subject,
    required this.month,
    required this.marksObtained,
    required this.totalMarks,
    required this.percentage,
    required this.gradeLetter,
    this.teacherFeedback,
    required this.updatedAt,
  });

  // Grade calculation logic
  static String calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  Map<String, dynamic> toMap() {
    return {
      'academy_id': academyId, // NEW
      'quiz_id': quizId,
      'student_id': studentId,
      'student_name': studentName,
      'class_id': classId,
      'subject': subject,
      'month': month,
      'marks_obtained': marksObtained,
      'total_marks': totalMarks,
      'percentage': percentage,
      'grade_letter': gradeLetter,
      'teacher_feedback': teacherFeedback,
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory TestMarkModel.fromMap(String id, Map<String, dynamic> map) {
    return TestMarkModel(
      id: id,
      academyId: map['academy_id'] ?? '', // NEW
      quizId: map['quiz_id'] ?? '',
      studentId: map['student_id'] ?? '',
      studentName: map['student_name'] ?? '',
      classId: map['class_id'] ?? '',
      subject: map['subject'] ?? 'General',
      month: map['month'] ?? '',
      marksObtained: (map['marks_obtained'] ?? 0).toDouble(),
      totalMarks: (map['total_marks'] ?? 0).toDouble(),
      percentage: (map['percentage'] ?? 0).toDouble(),
      gradeLetter: map['grade_letter'] ?? 'F',
      teacherFeedback: map['teacher_feedback'],
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
    );
  }
}
