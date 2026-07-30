import 'package:flutter/material.dart';
import '../data/models/quiz_model.dart';
import '../data/models/test_mark_model.dart';
import '../data/remote/quiz_service.dart';

class QuizProvider extends ChangeNotifier {
  final QuizService _service = QuizService();

  bool _loading = false;
  bool get loading => _loading;

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  // --- Actions ---

  Future<void> createQuiz({
    required String offeringId,
    required String title,
    required String subject,
    String? session,
    String? chapter,
    required String difficulty,
    required double totalMarks,
    required DateTime testDate,
    String? instructions,
    required List<QuizQuestion> questions,
  }) async {
    _setLoading(true);
    try {
      await _service.createQuiz(
        offeringId: offeringId,
        title: title,
        subject: subject,
        session: session,
        chapter: chapter,
        difficulty: difficulty,
        totalMarks: totalMarks,
        testDate: testDate,
        instructions: instructions,
        questions: questions,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteQuiz(String quizId, String academyId) async {
    _setLoading(true);
    try {
      await _service.deleteQuiz(quizId, academyId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadBulkMarks(
      String quizId, List<MarkRecordInput> records) async {
    _setLoading(true);
    try {
      await _service.upsertMarks(quizId, records);
    } finally {
      _setLoading(false);
    }
  }

  Future<GradeSuggestion> gradeSuggestion(
      String quizId, String questionId, String ocrText) {
    return _service.gradeSuggestion(quizId, questionId, ocrText);
  }

  // --- Reads ---

  /// Watch all tests created for a specific class offering. `academyId` is
  /// unused — the backend scopes admin/teacher access from the JWT — kept
  /// so call sites don't need to change.
  Stream<List<QuizModel>> watchTeacherQuizzes(
          String classId, String academyId) =>
      Stream.fromFuture(_service.fetchQuizzesForOffering(classId));

  /// Watch marks for a specific test (for Teacher/Admin review).
  Stream<List<TestMarkModel>> watchQuizResults(
          String quizId, String academyId) =>
      Stream.fromFuture(_service.fetchMarksForQuiz(quizId));

  /// Watch all test results for a specific student (for Report Card).
  Stream<List<TestMarkModel>> watchStudentResults(
          String uid, String academyId) =>
      Stream.fromFuture(_service.fetchStudentResults(uid));

  /// Compiles monthly report data for a class offering. There is no
  /// "all marks for a class" endpoint (marks are read per-quiz or
  /// per-student), so this fans out: quizzes for the offering, then marks
  /// per quiz, filtered to [month] and aggregated per student/subject.
  Stream<Map<String, dynamic>> watchMonthlyClassReport(
      String classId, String month, String academyId) {
    return Stream.fromFuture(() async {
      final quizzes = await _service.fetchQuizzesForOffering(classId);
      final monthlyQuizzes = quizzes.where((q) => q.month == month).toList();

      if (monthlyQuizzes.isEmpty) {
        return {
          'quizCount': 0,
          'subjects': [],
          'studentStats': <String, Map<String, dynamic>>{},
        };
      }

      final Map<String, Map<String, dynamic>> studentStats = {};

      for (final q in monthlyQuizzes) {
        final marks = await _service.fetchMarksForQuiz(q.id);
        for (final m in marks) {
          if (!studentStats.containsKey(m.studentId)) {
            studentStats[m.studentId] = {
              'name': m.studentName,
              'obtained': 0.0,
              'total': 0.0,
              'subjects': <String, Map<String, double>>{},
            };
          }

          final stats = studentStats[m.studentId]!;
          stats['obtained'] = (stats['obtained'] as double) + m.marksObtained;
          stats['total'] = (stats['total'] as double) + m.totalMarks;

          final subjects =
              stats['subjects'] as Map<String, Map<String, double>>;
          if (!subjects.containsKey(q.subject)) {
            subjects[q.subject] = {'obtained': 0.0, 'total': 0.0};
          }
          subjects[q.subject]!['obtained'] =
              subjects[q.subject]!['obtained']! + m.marksObtained;
          subjects[q.subject]!['total'] =
              subjects[q.subject]!['total']! + m.totalMarks;
        }
      }

      return {
        'quizCount': monthlyQuizzes.length,
        'subjects': monthlyQuizzes.map((q) => q.subject).toSet().toList(),
        'studentStats': studentStats,
      };
    }());
  }
}
