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

  Future<void> createQuiz(QuizModel quiz) async {
    _setLoading(true);
    try {
      await _service.createQuiz(quiz);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    _setLoading(true);
    try {
      await _service.deleteQuiz(quizId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> gradeBulk(List<TestMarkModel> marksList) async {
    _setLoading(true);
    try {
      await _service.uploadBulkMarks(marksList);
    } finally {
      _setLoading(false);
    }
  }

  // --- Streams (Real-time data) ---

  /// Watch all tests created for a specific class
  Stream<List<QuizModel>> watchTeacherQuizzes(String classId) {
    return _service.watchQuizzesByClass(classId);
  }

  /// Watch marks for a specific test (for Teacher/Admin review)
  Stream<List<TestMarkModel>> watchQuizResults(String quizId) {
    return _service.watchMarksByQuiz(quizId);
  }

  /// Watch all test results for a specific student (for Report Card)
  Stream<List<TestMarkModel>> watchStudentResults(String uid) {
    return _service.watchStudentMarks(uid);
  }

  /// Watch all marks for a class (for Admin Analytics)
  Stream<List<TestMarkModel>> watchClassResults(String classId) {
    return _service.watchClassMarks(classId);
  }

  /// NEW: Compiles monthly report data for a class
  Stream<Map<String, dynamic>> watchMonthlyClassReport(String classId, String month) {
    return watchClassResults(classId).asyncMap((marks) async {
      // 1. Get all quizzes for this class and month to know total possible marks
      final quizzes = await _service.watchQuizzesByClass(classId).first;
      final monthlyQuizzes = quizzes.where((q) => q.month == month).toList();
      
      if (monthlyQuizzes.isEmpty) return {'totalPossible': 0.0, 'students': {}};

      final Map<String, Map<String, dynamic>> studentStats = {};

      for (var q in monthlyQuizzes) {
        final qMarks = marks.where((m) => m.quizId == q.id).toList();
        for (var m in qMarks) {
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

          final subjects = stats['subjects'] as Map<String, Map<String, double>>;
          if (!subjects.containsKey(q.subject)) {
            subjects[q.subject] = {'obtained': 0.0, 'total': 0.0};
          }
          subjects[q.subject]!['obtained'] = subjects[q.subject]!['obtained']! + m.marksObtained;
          subjects[q.subject]!['total'] = subjects[q.subject]!['total']! + m.totalMarks;
        }
      }

      return {
        'quizCount': monthlyQuizzes.length,
        'subjects': monthlyQuizzes.map((q) => q.subject).toSet().toList(),
        'studentStats': studentStats,
      };
    });
  }
}
