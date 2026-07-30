import 'api_client.dart';
import '../models/app_user.dart';

/// Backed by the Node API's `/parents` endpoints instead of Firestore's
/// `linked_children` array field on the parent's user doc — linking is now
/// a proper `ParentChildLink` row server-side.
class ParentService {
  final ApiClient _api;
  ParentService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<List<AppUser>> getChildren() async {
    final response = await _api.get('/parents/children');
    final items = response.data['data'] as List<dynamic>;
    return items
        .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  /// Links a child either by exact email or by an already-resolved
  /// studentId (e.g. from [searchStudents]) — provide exactly one.
  Future<AppUser> linkChild({String? email, String? studentId}) async {
    final response = await _api.post('/parents/children', data: {
      if (email != null) 'email': email,
      if (studentId != null) 'studentId': studentId,
    });
    return AppUser.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> unlinkChild(String childId) async {
    await _api.delete('/parents/children/$childId');
  }

  Future<List<AppUser>> searchStudents(String query) async {
    final response = await _api.get('/parents/students/search',
        queryParameters: {'query': query, 'limit': 20});
    final items = response.data['data'] as List<dynamic>;
    return items
        .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
        .toList();
  }
}
