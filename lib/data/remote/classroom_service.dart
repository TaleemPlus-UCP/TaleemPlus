import 'api_client.dart';
import '../models/shared_resource.dart';
import '../models/student_query.dart';

/// Backed by the Node API's `/learning-resources` and `/student-queries`
/// endpoints instead of Firestore. No push channel exists server-side, so
/// `watchResources`/`watchQueriesForClass` are one-shot fetches wrapped in a
/// single-emission `Stream` — every existing `StreamBuilder` call site keeps
/// compiling and working, just without live updates; callers re-invoke
/// these after a write to refresh.
class ClassroomService {
  final ApiClient _api;
  ClassroomService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  // --- Shared Resources ---

  Future<void> uploadResource({
    required String offeringId,
    required String title,
    String? description,
    String? linkUrl,
  }) async {
    await _api.post('/learning-resources', data: {
      'offeringId': offeringId,
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (linkUrl != null && linkUrl.trim().isNotEmpty)
        'linkUrl': linkUrl.trim(),
    });
  }

  Future<void> deleteResource(String resourceId) async {
    await _api.delete('/learning-resources/$resourceId');
  }

  Stream<List<SharedResource>> watchResources(
          String classId, String academyId) =>
      Stream.fromFuture(_fetchResources(classId));

  Future<List<SharedResource>> _fetchResources(String offeringId) async {
    final response = await _api.get('/learning-resources',
        queryParameters: {'offeringId': offeringId});
    final items = response.data['data'] as List<dynamic>;
    return items
        .map((r) => SharedResource.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // --- Student Queries ---

  Future<void> postQuery(
      {required String offeringId, required String question}) async {
    await _api.post('/student-queries', data: {
      'offeringId': offeringId,
      'question': question.trim(),
    });
  }

  Future<void> answerQuery(String queryId, String answer) async {
    await _api
        .patch('/student-queries/$queryId', data: {'answer': answer.trim()});
  }

  /// Every question (and answer) posted to this offering — a shared
  /// class-discussion wall, not scoped to the asker.
  Stream<List<StudentQuery>> watchQueriesForClass(
          String classId, String academyId) =>
      Stream.fromFuture(_fetchQueries(classId));

  Future<List<StudentQuery>> _fetchQueries(String offeringId) async {
    final response = await _api
        .get('/student-queries', queryParameters: {'offeringId': offeringId});
    final items = response.data['data'] as List<dynamic>;
    return items
        .map((q) => StudentQuery.fromJson(q as Map<String, dynamic>))
        .toList();
  }
}
