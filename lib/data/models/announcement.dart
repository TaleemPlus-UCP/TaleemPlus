import 'package:cloud_firestore/cloud_firestore.dart';

/// A broadcast message from an admin to one or more user roles.
class Announcement {
  final String id;
  final String title;
  final String message;
  final List<String> targetRoles;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.targetRoles,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isForAll => targetRoles.contains('all');

  bool isForRole(String role) => isForAll || targetRoles.contains(role);

  /// Human-readable badge like "Teachers", "Students & Parents", "Everyone".
  String get targetLabel {
    if (isForAll) return 'Everyone';
    final labels = targetRoles.map((r) {
      switch (r) {
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
    if (labels.length == 1) return labels.first;
    if (labels.length == 2) return '${labels[0]} & ${labels[1]}';
    return labels.join(', ');
  }

  Map<String, dynamic> toMap() => {
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