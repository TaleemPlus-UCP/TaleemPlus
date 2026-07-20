import 'package:cloud_firestore/cloud_firestore.dart';

/// A person managed by the Admin: a teacher, student, or parent.
class AcademyMember {
  final String id;
  final String academyId;
  final String fullName;
  final String email;
  final String phone;
  final String role; // 'teacher' | 'student' | 'parent'
  final String extra; // roll number / qualification / relation
  final String status;
  final DateTime createdAt;

  const AcademyMember({
    required this.id,
    required this.academyId,
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
      'academy_id': academyId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'extra': extra,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory AcademyMember.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['created_at'];
    return AcademyMember(
      id: id,
      academyId: (map['academy_id'] ?? '') as String,
      fullName: (map['full_name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      role: (map['role'] ?? 'student') as String,
      extra: (map['extra'] ?? '') as String,
      status: (map['status'] ?? 'active') as String,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}