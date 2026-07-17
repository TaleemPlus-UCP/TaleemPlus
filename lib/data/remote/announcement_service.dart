import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _db;
  AnnouncementService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('announcements');

  /// Admin: create a new broadcast.
  Future<void> create({
    required String title,
    required String message,
    required List<String> targetRoles,
    required String createdByUid,
    required String createdByName,
  }) async {
    await _col.add({
      'title': title.trim(),
      'message': message.trim(),
      'target_roles': targetRoles,
      'created_by_uid': createdByUid,
      'created_by_name': createdByName,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
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

  /// Admin: real-time list of ALL announcements, newest first.
  Stream<List<Announcement>> watchAll() {
    return _col.orderBy('created_at', descending: true).snapshots().map(
          (snap) => snap.docs
          .map((d) => Announcement.fromMap(d.id, d.data()))
          .toList(),
    );
  }

  /// Teacher/Student/Parent: real-time list for their role.
  Stream<List<Announcement>> watchForRole(String role) {
    return watchAll()
        .map((list) => list.where((a) => a.isForRole(role)).toList());
  }
}