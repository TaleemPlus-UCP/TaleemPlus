import '../models/quiz_model.dart';
import '../models/test_mark_model.dart';
import 'api_client.dart';

class QuizService {
  final ApiClient _api = ApiClient();

  Future<void> createQuiz(QuizModel quiz) async {
    await _api.post('/quizzes', {
      'classId': quiz.classId,
      'classLabel': quiz.classLabel,
      'title': quiz.title,
      'subject': quiz.subject,
      'totalMarks': quiz.totalMarks,
      'instructions': quiz.instructions,
      'questions': quiz.questions.map((q) => q.toMap()).toList(),
    });
  }

  Future<void> updateQuestions(
      String quizId, List<QuizQuestion> questions) async {
    // handled via quiz update
  }

  Stream<List<QuizModel>> watchQuizzesByClass(
      String classId, String academyId) async* {
    try {
      final res = await _api.get('/quizzes?classId=$classId');
      final list = res as List;
      yield list
          .map((item) => QuizModel.fromMap(item['id'] ?? '', item))
          .toList();
    } catch (_) {
      yield [];
    }
  }

  Stream<List<QuizModel>> watchQuizzesForClasses(
      List<String> classIds, String academyId) async* {
    try {
      final res = await _api.get('/quizzes');
      final list = res as List;
      yield list
          .map((item) => QuizModel.fromMap(item['id'] ?? '', item))
          .where((q) => classIds.contains(q.classId))
          .toList();
    } catch (_) {
      yield [];
    }
  }

  Future<void> deleteQuiz(String quizId, String academyId) async {
    // backend delete
  }

  Future<void> saveTestMark(TestMarkModel mark) async {
    await _api.post('/quizzes/marks', {
      'quizId': mark.quizId,
      'studentId': mark.studentId,
      'marksObtained': mark.marksObtained,
      'teacherFeedback': mark.teacherFeedback,
    });
  }

  Stream<List<TestMarkModel>> watchStudentMarks(
      String studentId, String academyId) async* {
    try {
      final res = await _api.get('/quizzes/marks/student/$studentId');
      final list = res as List;
      yield list
          .map((item) => TestMarkModel.fromMap(item['id'] ?? '', item))
          .toList();
    } catch (_) {
      yield [];
    }
  }

  Future<List<TestMarkModel>> getAllAcademyMarks(String academyId) async {
    return [];
  }

  Future<void> uploadBulkMarks(List<TestMarkModel> marks) async {
    for (final m in marks) {
      await saveTestMark(m);
    }
  }

  Future<void> deleteMark(String markId, String academyId) async {
    // delete mark stub
  }

  Stream<List<TestMarkModel>> watchMarksByQuiz(
      String quizId, String academyId) async* {
    yield [];
  }

  Stream<List<TestMarkModel>> watchClassMarks(
      String classId, String academyId) async* {
    yield [];
  }
}
