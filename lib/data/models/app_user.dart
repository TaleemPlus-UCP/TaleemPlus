import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String accountStatus;
  final String? academyName; // New: For academy registration
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.accountStatus = 'active',
    this.academyName,
    this.createdAt,
  });

  bool get isApproved => accountStatus.toLowerCase() == 'active';
  bool get isPending => accountStatus.toLowerCase() == 'pending';
  bool get isRejected => accountStatus.toLowerCase() == 'rejected';

  Map<String, dynamic> toMap() {
    return {
      'user_id': uid,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role.value,
      'account_status': accountStatus,
      'academy_name': academyName,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final ts = map['created_at'];
    return AppUser(
      uid: uid,
      fullName: (map['full_name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phoneNumber: (map['phone_number'] ?? '') as String,
      role: UserRoleX.fromValue((map['role'] ?? 'student') as String),
      accountStatus: (map['account_status'] ?? 'active') as String,
      academyName: map['academy_name'] as String?,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
