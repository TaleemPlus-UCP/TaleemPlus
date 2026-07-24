import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../models/announcement.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class AnnouncementService {
  final FirebaseFirestore _db;
  final AuthService _authService;
  final NotificationService _notificationService;
  AnnouncementService({
    FirebaseFirestore? db,
    AuthService? authService,
    NotificationService? notificationService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService(),
        _notificationService = notificationService ?? NotificationService();

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('announcements');

  /// Admin/Teacher: create a new broadcast tied to an academy, and notify
  /// every approved user in the targeted role(s) so they see a badge/alert
  /// instead of only finding out if they happen to open Announcements.
  Future<void> create({
    required String title,
    required String message,
    required List<String> targetRoles,
    required String createdByUid,
    required String createdByName,
    required String academyId, // NEW
  }) async {
    await _col.add({
      'title': title.trim(),
      'message': message.trim(),
      'target_roles': targetRoles,
      'created_by_uid': createdByUid,
      'created_by_name': createdByName,
      'academy_id': academyId, // NEW
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await _notifyTargets(
      title: title.trim(),
      targetRoles: targetRoles,
      academyId: academyId,
      excludeUid: createdByUid,
    );
  }

  /// Best-effort: a notification-delivery failure shouldn't block the
  /// announcement itself from being posted (it already saved successfully).
  Future<void> _notifyTargets({
    required String title,
    required List<String> targetRoles,
    required String academyId,
    required String excludeUid,
  }) async {
    try {
      final isForAll = targetRoles.any((r) => r.toLowerCase() == 'all');
      final roles = isForAll
          ? [UserRole.teacher, UserRole.student, UserRole.parent]
          : targetRoles
              .map((r) => UserRoleX.fromValue(r.toLowerCase()))
              .toSet()
              .toList();

      final recipientIds = <String>{};
      for (final role in roles) {
        final users = await _authService.getApprovedByRole(role, academyId);
        recipientIds.addAll(
            users.map((u) => u.uid).where((uid) => uid != excludeUid));
      }

      if (recipientIds.isNotEmpty) {
        await _notificationService.sendToMany(
          academyId: academyId,
          recipientIds: recipientIds.toList(),
          title: 'New Announcement',
          message: title,
          type: 'announcement',
        );
      }
    } catch (e) {
      debugPrint('Announcement notification error: $e');
    }
  }

  Future<void> update({
    required String id,
    required String title,
    required String message,
    required List<String> targetRoles,
  }) async {
    await _col.doc(id).update({
      'title': title.trim(),
      'message': message.trim(),
      'target_roles': targetRoles,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Admin: real-time list of academy-specific announcements.
  Stream<List<Announcement>> watchAll(String academyId) {
    return _col.where('academy_id', isEqualTo: academyId).snapshots().map(
      (snap) {
        final list =
            snap.docs.map((d) => Announcement.fromMap(d.id, d.data())).toList();
        // Client-side sorting (Newest First) to avoid mandatory composite index
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  /// Teacher/Student/Parent: real-time list for their role in their academy.
  Stream<List<Announcement>> watchForRole(String role, String academyId) {
    return _col.where('academy_id', isEqualTo: academyId).snapshots().map(
      (snap) {
        final list = snap.docs
            .map((d) => Announcement.fromMap(d.id, d.data()))
            .where((a) => a.isForRole(role))
            .toList();
        // Client-side sorting (Newest First) to avoid mandatory composite index
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }
}
