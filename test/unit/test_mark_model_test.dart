import 'package:flutter_test/flutter_test.dart';
import 'package:taleemplus_app/data/models/test_mark_model.dart';

void main() {
  group('TestMarkModel.calculateGrade', () {
    test('boundaries map to the correct letter grade', () {
      expect(TestMarkModel.calculateGrade(100), 'A+');
      expect(TestMarkModel.calculateGrade(90), 'A+');
      expect(TestMarkModel.calculateGrade(89.9), 'A');
      expect(TestMarkModel.calculateGrade(80), 'A');
      expect(TestMarkModel.calculateGrade(79.9), 'B');
      expect(TestMarkModel.calculateGrade(70), 'B');
      expect(TestMarkModel.calculateGrade(69.9), 'C');
      expect(TestMarkModel.calculateGrade(60), 'C');
      expect(TestMarkModel.calculateGrade(59.9), 'D');
      expect(TestMarkModel.calculateGrade(50), 'D');
      expect(TestMarkModel.calculateGrade(49.9), 'F');
      expect(TestMarkModel.calculateGrade(0), 'F');
    });
  });

  group('TestMarkModel.fromJson', () {
    test('parses the backend response shape', () {
      final mark = TestMarkModel.fromJson({
        'id': 'mark-1',
        'academyId': 'academy-1',
        'quiz': {
          'id': 'quiz-1',
          'title': 'Live Quiz',
          'subject': 'Physics',
          'testDate': '2026-07-20T00:00:00.000Z'
        },
        'student': {'id': 'student-1', 'fullName': 'Demo Student'},
        'marksObtained': 8,
        'totalMarks': 10,
        'percentage': 80,
        'gradeLetter': 'A',
        'teacherFeedback': null,
        'updatedAt': '2026-07-29T23:35:50.372Z',
      });

      expect(mark.quizId, 'quiz-1');
      expect(mark.quizTitle, 'Live Quiz');
      expect(mark.subject, 'Physics');
      expect(mark.studentId, 'student-1');
      expect(mark.studentName, 'Demo Student');
      expect(mark.marksObtained, 8);
      expect(mark.totalMarks, 10);
      expect(mark.percentage, 80);
      expect(mark.gradeLetter, 'A');
    });
  });
}
