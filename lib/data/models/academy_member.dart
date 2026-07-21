/// A person managed by the Admin: a teacher, student, or parent.
class AcademyMember {
  final String id;
  final String academyId; // NEW
  final String fullName;
  final String email;
  final String phone;
  final String role; // 'teacher' | 'student' | 'parent'
  final String extra; // roll number / qualification / relation
  final String status;
  final DateTime createdAt;

  const AcademyMember({
    required this.id,
    required this.academyId, // NEW
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.extra = '',
    this.status = 'active',
    required this.createdAt,
  });

  static String extraLabelFor(String role) {
    switch (role) {
      case 'teacher':
        return 'Qualification / Subject';
      case 'student':
        return 'Roll Number';
      case 'parent':
        return "Child's Name";
      default:
        return 'Details';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academy_id': academyId, // NEW
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'extra': extra,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AcademyMember.fromMap(Map<String, dynamic> map) {
    return AcademyMember(
      id: map['id'] as String,
      academyId: (map['academy_id'] ?? '') as String, // NEW
      fullName: (map['full_name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      role: (map['role'] ?? 'student') as String,
      extra: (map['extra'] ?? '') as String,
      status: (map['status'] ?? 'active') as String,
      createdAt: DateTime.tryParse((map['created_at'] ?? '') as String) ??
          DateTime.now(),
    );
  }
}
