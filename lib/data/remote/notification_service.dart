import 'api_client.dart';
import '../models/notification_model.dart';

/// Backed by the Node API's `/notifications` endpoints instead of Firestore.
///
/// There is no client-callable "send a notification" endpoint anymore —
/// every notification is now created server-side as a side effect of the
/// action that warrants it (approving/rejecting a user, posting an
/// announcement, etc.), so `send`/`sendToMany` have no REST equivalent and
/// are intentionally not carried over. Callers that used to invoke them
/// directly (see `approval_requests_screen.dart`) no longer need to —
/// `AuthService().approveUser`/`.rejectUser` already trigger the backend's
/// own notification.
class NotificationService {
  final ApiClient _api;
  NotificationService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  /// Most recent 50 notifications for the current user (matches the old
  /// Firestore query's cap). `userId`/`academyId` are unused — the backend
  /// scopes to the caller via the JWT — kept only so call sites don't need
  /// to change.
  Stream<List<NotificationModel>> watchForUser(
      String userId, String academyId) {
    return Stream.fromFuture(() async {
      final response =
          await _api.get('/notifications', queryParameters: {'limit': 50});
      final items = response.data['data'] as List<dynamic>;
      return items
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
    }());
  }

  Future<void> markAsRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  /// `academyId` is unused — kept only so call sites don't need to change.
  Future<void> markAllAsRead(String userId, String academyId) async {
    await _api.post('/notifications/mark-all-read');
  }
}
