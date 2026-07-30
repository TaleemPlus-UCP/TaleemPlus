import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() => {
        'academy_id': academyId,
        'class_id': classId,
        'student_id': studentId,
        'student_name': studentName,
        'teacher_id': teacherId,
        'question': question.trim(),
        'answer': answer,
        'is_resolved': isResolved,
        'created_at': FieldValue.serverTimestamp(),
        'answered_at':
            answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
      };

  factory StudentQuery.fromMap(String id, Map<String, dynamic> map) {
    return StudentQuery(
      id: id,
      academyId: map['academy_id'] ?? '',
      classId: map['class_id'] ?? '',
      studentId: map['student_id'] ?? '',
      studentName: map['student_name'] ?? 'Student',
      teacherId: map['teacher_id'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'],
      isResolved: map['is_resolved'] ?? false,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      answeredAt: (map['answered_at'] as Timestamp?)?.toDate(),
    );
  }
}
