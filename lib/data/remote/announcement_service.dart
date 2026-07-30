import 'api_client.dart';
import '../models/announcement.dart';

/// Backed by the Node API's `/announcements` endpoints instead of Firestore.
///
/// Notification fan-out to targeted users now happens entirely server-side
/// as part of `POST /announcements` (see the backend's `announcementsService
/// .notifyTargets`), so this no longer orchestrates `AuthService` +
/// `NotificationService` calls itself.
class AnnouncementService {
  final ApiClient _api;
  AnnouncementService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  /// `targetRoles` uses `['all']` as a sentinel for "everyone" (matching
  /// every existing caller's convention) rather than a separate `isForAll`
  /// parameter.
  Future<void> create({
    required String title,
    required String message,
    required List<String> targetRoles,
    required String createdByUid,
    required String createdByName,
    required String academyId,
  }) async {
    final isForAll = targetRoles.any((r) => r.toLowerCase() == 'all');
    await _api.post('/announcements', data: {
      'title': title.trim(),
      'message': message.trim(),
      'isForAll': isForAll,
      'targetRoles':
          isForAll ? [] : targetRoles.map((r) => r.toUpperCase()).toList(),
    });
  }

  Future<void> update({
    required String id,
    required String title,
    required String message,
    required List<String> targetRoles,
  }) async {
    final isForAll = targetRoles.any((r) => r.toLowerCase() == 'all');
    await _api.patch('/announcements/$id', data: {
      'title': title.trim(),
      'message': message.trim(),
      'isForAll': isForAll,
      'targetRoles':
          isForAll ? [] : targetRoles.map((r) => r.toUpperCase()).toList(),
    });
  }

  Future<void> delete(String id) async {
    await _api.delete('/announcements/$id');
  }

  Future<List<Announcement>> _fetchList() async {
    final response =
        await _api.get('/announcements', queryParameters: {'limit': 200});
    final items = response.data['data'] as List<dynamic>;
    return items
        .map((a) => Announcement.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Admin: every announcement in the academy. Teacher: the backend scopes
  /// this down to what targets them automatically (same call as
  /// [watchForRole]) — kept as a separate method only so call sites don't
  /// need to change.
  Stream<List<Announcement>> watchAll(String academyId) =>
      Stream.fromFuture(_fetchList());

  /// Teacher/Student/Parent: announcements targeting their own role.
  Stream<List<Announcement>> watchForRole(String role, String academyId) =>
      Stream.fromFuture(_fetchList());
}
