import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('notifications');

  /// Send a notification to a specific user
  Future<void> send({
    required String academyId,
    required String recipientId,
    required String title,
    required String message,
    required String type,
  }) async {
    final doc = _col.doc();
    final notif = NotificationModel(
      id: doc.id,
      academyId: academyId,
      recipientId: recipientId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
    );
    await doc.set(notif.toMap());
  }

  /// Watch notifications for a specific user (Real-time)
  Stream<List<NotificationModel>> watchForUser(String userId, String academyId) {
    return _col
        .where('academy_id', isEqualTo: academyId)
        .where('recipient_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> markAsRead(String id) async {
    await _col.doc(id).update({'is_read': true});
  }

  Future<void> markAllAsRead(String userId, String academyId) async {
    final batch = _db.batch();
    final snap = await _col
        .where('academy_id', isEqualTo: academyId)
        .where('recipient_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .get();
    
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }
}
