/// A broadcast message from an admin/teacher to one or more user roles.
class Announcement {
  final String id;
  final String academyId;
  final String title;
  final String message;
  final bool isForAll;
  final List<String> targetRoles; // lowercase role names; empty when isForAll
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Announcement({
    required this.id,
    required this.academyId,
    required this.title,
    required this.message,
    required this.isForAll,
    required this.targetRoles,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
    this.updatedAt,
  });

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

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final roles = (json['targetRoles'] as List<dynamic>?) ?? const [];
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    return Announcement(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isForAll: json['isForAll'] as bool,
      targetRoles: roles.map((r) => (r as String).toLowerCase()).toList(),
      createdByUid: (createdBy?['id'] as String?) ?? '',
      createdByName: (createdBy?['fullName'] as String?) ?? 'Admin',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
