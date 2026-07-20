import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _db;
  AnnouncementService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('announcements');

  /// Admin: create a new broadcast tied to an academy.
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
    return _col
        .where('academy_id', isEqualTo: academyId)
        .snapshots().map(
          (snap) {
            final list = snap.docs
              .map((d) => Announcement.fromMap(d.id, d.data()))
              .toList();
            // Client-side sorting (Newest First) to avoid mandatory composite index
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          },
    );
  }

  /// Teacher/Student/Parent: real-time list for their role in their academy.
  Stream<List<Announcement>> watchForRole(String role, String academyId) {
    return _col
        .where('academy_id', isEqualTo: academyId)
        .snapshots().map(
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