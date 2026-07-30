import 'package:cloud_firestore/cloud_firestore.dart';

/// A broadcast message from an admin to one or more user roles.
class Announcement {
  final String id;
  final String academyId; // NEW
  final String title;
  final String message;
  final List<String> targetRoles;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Announcement({
    required this.id,
    required this.academyId,
    required this.title,
    required this.message,
    required this.targetRoles,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isForAll => targetRoles.any((r) => r.toLowerCase() == 'all');

  bool isForRole(String role) {
    if (isForAll) return true;
    final rLower = role.toLowerCase().trim();
    return targetRoles.any((tr) => tr.toLowerCase().trim() == rLower);
  }

  /// Human-readable badge like "Teachers", "Students & Parents", "Everyone".
  String get targetLabel {
    if (isForAll) return 'Everyone';
    final labels = targetRoles.map((r) {
      final rLower = r.toLowerCase().trim();
      switch (rLower) {
        case 'teacher':
          return 'Teachers';
        case 'student':
          return 'Students';
        case 'parent':
          return 'Parents';
        default:
          return r;
      }
    }).toList();
    if (labels.isEmpty) return 'None';
    if (labels.length == 1) return labels.first;
    if (labels.length == 2) return '${labels[0]} & ${labels[1]}';
    return labels.join(', ');
  }

  Map<String, dynamic> toMap() => {
        'academy_id': academyId,
        'title': title,
        'message': message,
        'target_roles': targetRoles,
        'created_by_uid': createdByUid,
        'created_by_name': createdByName,
        'created_at': createdAt.millisecondsSinceEpoch == 0
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt),
        'updated_at': FieldValue.serverTimestamp(),
      };

  factory Announcement.fromMap(String id, Map<String, dynamic> map) {
    final rolesRaw = map['target_roles'];
    final roles =
        (rolesRaw is List) ? rolesRaw.cast<String>() : <String>['all'];
    final ts = map['created_at'];
    final ts2 = map['updated_at'];
    return Announcement(
      id: id,
      academyId: (map['academy_id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      message: (map['message'] ?? '') as String,
      targetRoles: roles,
      createdByUid: (map['created_by_uid'] ?? '') as String,
      createdByName: (map['created_by_name'] ?? 'Admin') as String,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      updatedAt: ts2 is Timestamp ? ts2.toDate() : null,
    );
  }
}
