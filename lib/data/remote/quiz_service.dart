import 'api_client.dart';
import '../models/quiz_model.dart';
import '../models/test_mark_model.dart';

/// Backed by the Node API's `/quizzes` and `/marks` endpoints instead of
/// Firestore. Quiz definitions (including the answer key) are staff-only —
/// students/parents only ever see results through the Marks endpoints.
class QuizService {
  final ApiClient _api;
  QuizService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<QuizModel> createQuiz({
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
    final response = await _api.post('/quizzes', data: {
      'offeringId': offeringId,
      'title': title,
      'subject': subject,
      if (session != null && session.isNotEmpty) 'session': session,
      if (chapter != null && chapter.isNotEmpty) 'chapter': chapter,
      'difficulty': difficulty.toUpperCase(),
      'totalMarks': totalMarks,
      'testDate': _dateOnly(testDate),
      if (instructions != null && instructions.isNotEmpty)
        'instructions': instructions,
      'questions': questions.map((q) => q.toJson()).toList(),
    });
    return QuizModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteQuiz(String quizId, String academyId) async {
    await _api.delete('/quizzes/$quizId');
  }

  /// Quizzes for one class offering — admin sees any; teacher only sees
  /// their own (enforced server-side either way).
  Future<List<QuizModel>> fetchQuizzesForOffering(String offeringId) async {
    final response = await _api.get('/quizzes',
        queryParameters: {'offeringId': offeringId, 'limit': 100});
    final items = response.data['data'] as List<dynamic>;
    final list = items
        .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000)));
    return list;
  }

  Future<List<TestMarkModel>> fetchMarksForQuiz(String quizId) async {
    final response = await _api.get('/quizzes/$quizId/marks');
    final items = response.data['data'] as List<dynamic>;
    return items
        .map((m) => TestMarkModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<TestMarkModel>> fetchStudentResults(String studentId) async {
    final response = await _api
        .get('/marks/students/$studentId', queryParameters: {'limit': 100});
    final items = response.data['data'] as List<dynamic>;
    final list = items
        .map((m) => TestMarkModel.fromJson(m as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<List<TestMarkModel>> upsertMarks(
      String quizId, List<MarkRecordInput> records) async {
    final response = await _api.put('/quizzes/$quizId/marks', data: {
      'records': records.map((r) => r.toJson()).toList(),
    });
    final items = response.data['data'] as List<dynamic>;
    return items
        .map((m) => TestMarkModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// AI Smart Grader: scores one Short/Long answer against the question's
  /// grading keywords, given already-OCR'd text (OCR itself stays an
  /// on-device ML Kit concern).
  Future<GradeSuggestion> gradeSuggestion(
      String quizId, String questionId, String ocrText) async {
    final response = await _api
        .post('/quizzes/$quizId/questions/$questionId/grade-suggestion', data: {
      'ocrText': ocrText,
    });
    return GradeSuggestion.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  static String _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);
}

class GradeSuggestion {
  final int matches;
  final int keywordCount;
  final List<String> matchedKeywords;
  final double suggestedMarks;

  const GradeSuggestion({
    required this.matches,
    required this.keywordCount,
    required this.matchedKeywords,
    required this.suggestedMarks,
  });

  factory GradeSuggestion.fromJson(Map<String, dynamic> json) {
    return GradeSuggestion(
      matches: json['matches'] as int,
      keywordCount: json['keywordCount'] as int,
      matchedKeywords: (json['matchedKeywords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      suggestedMarks: (json['suggestedMarks'] as num).toDouble(),
    );
  }
}
