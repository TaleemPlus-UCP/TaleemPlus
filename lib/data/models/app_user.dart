import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String accountStatus;
  final String? academyName; // For display
  final String? academyId; // For multi-tenancy scoping
  final String? academyAddress;
  final String? academyPhone;
  final String? academyLogo; // NEW: URL for branding
  final String? academyCode; // NEW: Short code for joining (e.g. SRS-101)
  final DateTime? createdAt;
  final DateTime? joiningDate; // NEW: When the user joined/was added
  final List<String>
      assignedSections; // NEW: Sections assigned (e.g. ['A', 'B'])
  final List<String> linkedChildren; // NEW: Child UIDs (for Parents)
  final String?
      extraInfo; // Role-specific note (qualification/roll no./relation)

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.accountStatus = 'active',
    this.academyName,
    this.academyId,
    this.academyAddress,
    this.academyPhone,
    this.academyLogo,
    this.academyCode,
    this.createdAt,
    this.joiningDate,
    this.assignedSections = const [],
    this.linkedChildren = const [],
    this.extraInfo,
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
      'academy_id': academyId,
      'academy_address': academyAddress,
      'academy_phone': academyPhone,
      'academy_logo': academyLogo,
      'academy_code': academyCode,
      'sections': assignedSections,
      'linked_children': linkedChildren,
      'extra_info': extraInfo,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'joining_date': joiningDate != null
          ? Timestamp.fromDate(joiningDate!)
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
      academyId: map['academy_id'] as String?,
      academyAddress: map['academy_address'] as String?,
      academyPhone: map['academy_phone'] as String?,
      academyLogo: map['academy_logo'] as String?,
      academyCode: map['academy_code'] as String?,
      createdAt: ts is Timestamp ? ts.toDate() : null,
      joiningDate: map['joining_date'] is Timestamp
          ? (map['joining_date'] as Timestamp).toDate()
          : (ts is Timestamp ? ts.toDate() : null), // Fallback to createdAt
      assignedSections: (map['sections'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      linkedChildren: (map['linked_children'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      extraInfo: map['extra_info'] as String?,
    );
  }
}
