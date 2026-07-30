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
    this.extraInfo,
  });

  bool get isApproved => accountStatus.toLowerCase() == 'active';
  bool get isPending => accountStatus.toLowerCase() == 'pending';
  bool get isRejected => accountStatus.toLowerCase() == 'rejected';

  /// Parses the Node backend's `toUserResponse` JSON shape (nested
  /// `academy` object, uppercase enum strings) — used by every REST-backed
  /// call in [AuthService].
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final academy = json['academy'] as Map<String, dynamic>?;
    return AppUser(
      uid: json['id'] as String,
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phoneNumber: (json['phoneNumber'] ?? '') as String,
      role: UserRoleX.fromValue(
          ((json['role'] ?? 'student') as String).toLowerCase()),
      accountStatus: (json['accountStatus'] ?? 'active') as String,
      academyName: academy?['name'] as String?,
      academyId: academy?['id'] as String?,
      academyAddress: academy?['address'] as String?,
      academyPhone: academy?['phone'] as String?,
      academyLogo: academy?['logoUrl'] as String?,
      academyCode: academy?['code'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      joiningDate: json['joiningDate'] != null
          ? DateTime.tryParse(json['joiningDate'] as String)
          : null,
      assignedSections: (json['assignedSections'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      extraInfo: json['extraInfo'] as String?,
    );
  }
}
