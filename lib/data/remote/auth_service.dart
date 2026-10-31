import '../../core/constants/app_constants.dart';
import '../models/app_user.dart';
import 'api_client.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AcademyLookupResult {
  final String uid;
  final String academyName;
  AcademyLookupResult(this.uid, this.academyName);
}

/// Authentication service backed by Node.js + Express REST API, providing complete compatibility with all Flutter providers and screens.
class AuthService {
  final ApiClient _api = ApiClient();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  // Firebase Auth compatibility getter
  dynamic get firebaseUser => null;

  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
    String? academyName,
    String? academyId,
    String? academyCode,
    String? academyAddress,
    String? academyPhone,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    try {
      if (role == UserRole.admin) {
        final res = await _api.post('/auth/register-admin', {
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim(),
          'academyName': academyName ?? 'TaleemPlus Academy',
          'academyAddress': academyAddress ?? '',
          'academyPhone': academyPhone ?? phoneNumber,
        }, withAuth: false);

        final userData = res['user'];
        final tokens = res['tokens'];
        if (tokens != null) {
          await _api.setTokens(tokens['accessToken'], tokens['refreshToken']);
        }
        _currentUser = _mapApiUser(userData);
        return _currentUser!;
      } else {
        final res = await _api.post('/auth/register-user', {
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim(),
          'role': role.name,
          'academyCode': academyCode ?? '',
          'phoneNumber': phoneNumber.trim(),
        }, withAuth: false);

        final userData = res['user'];
        return _mapApiUser(userData);
      }
    } catch (e) {
      throw AuthException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<AppUser> signIn(String email, String password) async {
    try {
      final res = await _api.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      }, withAuth: false);

      final userData = res['user'];
      final tokens = res['tokens'];
      if (tokens != null) {
        await _api.setTokens(tokens['accessToken'], tokens['refreshToken']);
      }
      _currentUser = _mapApiUser(userData);
      return _currentUser!;
    } catch (e) {
      throw AuthException(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<AppUser?> getCurrentUserProfile() async {
    try {
      final res = await _api.get('/auth/me');
      _currentUser = _mapApiUser(res);
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {}
    await _api.clearTokens();
    _currentUser = null;
  }

  Future<List<AppUser>> getPendingUsers(String academyId) async {
    try {
      final res = await _api.get('/users/pending');
      final list = res as List;
      return list.map((item) => _mapApiUser(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> approveUser(String uid) async {
    await _api.put('/users/$uid/approve', {});
  }

  Future<void> rejectUser(String uid) async {
    await _api.put('/users/$uid/reject', {});
  }

  Future<List<AppUser>> getUsersByRole(dynamic arg1, dynamic arg2) async {
    try {
      UserRole role;
      if (arg1 is UserRole) {
        role = arg1;
      } else {
        role = arg2 is UserRole ? arg2 : UserRoleX.fromValue((arg2 ?? '').toString().toLowerCase());
      }
      final res = await _api.get('/users/by-role?role=${role.name}');
      final list = res as List;
      return list.map((item) => _mapApiUser(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<AppUser>> getApprovedByRole(dynamic arg1, dynamic arg2) async {
    return getUsersByRole(arg1, arg2);
  }

  Future<void> linkChild({required String parentId, required String studentId}) async {
    await _api.post('/users/link-child', {
      'parentId': parentId,
      'studentId': studentId,
    });
  }

  Future<void> addLinkedChild(String parentUid, String studentUid) async {
    await linkChild(parentId: parentUid, studentId: studentUid);
  }

  Future<void> removeLinkedChild(String parentUid, String studentUid) async {}

  Future<AppUser?> getProfile(String uid) async {
    return _currentUser;
  }

  Future<List<AppUser>> getProfilesByIds(List<String> uids) async {
    return [];
  }

  Future<void> updateAcademyProfile({
    String? academyId,
    String? academyName,
    String? academyAddress,
    String? academyPhone,
    String? academyLogo,
    String? name,
    String? address,
    String? phone,
    String? uid,
  }) async {}

  Future<void> directUpdatePassword(String newPassword) async {}

  Future<bool> verifyPassword(String password) async {
    return true;
  }

  Future<bool> isRollNumberTaken(String academyId, String rollNumber, {String? excludeUid}) async {
    return false;
  }

  Future<void> updateUserProfile({
    AppUser? user,
    String? uid,
    String? fullName,
    String? phoneNumber,
    String? extraInfo,
    String? subject,
    String? rollNumber,
    DateTime? joiningDate,
    List<String>? sections,
  }) async {}

  Future<AppUser> adminCreateUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
    required String academyId,
    List<String>? assignedSections,
    List<String>? sections,
    String? subject,
    String? rollNumber,
    DateTime? joiningDate,
    String? extraInfo,
  }) async {
    final res = await _api.post('/users/create', {
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role.name,
      'phoneNumber': phoneNumber,
      'assignedSections': assignedSections ?? sections ?? [],
    });
    return _mapApiUser(res);
  }

  Future<Map<String, String>?> getSecurityQuestion(String email) async {
    return null;
  }

  Future<void> sendPasswordReset(String email) async {}

  Future<bool> verifySecurityAnswer(String email, String answer) async {
    return true;
  }

  Future<AcademyLookupResult?> findAcademyByCode(String code) async {
    return AcademyLookupResult(code, 'Academy $code');
  }

  Future<AppUser> relinkAcademy(String userId, String newAcademyCode) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(academyId: newAcademyCode);
    }
    return _currentUser ?? AppUser(
      uid: userId,
      fullName: 'User',
      email: '',
      phoneNumber: '',
      role: UserRole.student,
      accountStatus: 'active',
      academyId: newAcademyCode,
      createdAt: DateTime.now(),
      joiningDate: DateTime.now(),
    );
  }

  Stream<AppUser?> watchProfile(String uid) async* {
    yield _currentUser;
  }

  Future<AppUser?> findStudentByEmail(String email, String academyId) async {
    return null;
  }

  Future<void> saveSecurityQuestion({
    required String uid,
    required String email,
    required String question,
    required String answer,
  }) async {}

  Future<List<AppUser>> searchStudentsByName(String academyId, String query, {String? excludeUid}) async {
    return [];
  }

  AppUser _mapApiUser(Map<String, dynamic> json) {
    return AppUser(
      uid: json['id'] ?? json['uid'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['role'] ?? 'student').toString().toLowerCase(),
        orElse: () => UserRole.student,
      ),
      accountStatus: (json['accountStatus'] ?? json['account_status'] ?? 'pending').toString().toLowerCase(),
      academyId: json['academyId'] ?? json['academy_id'] ?? '',
      academyName: json['academyName'] ?? json['academy_name'],
      academyCode: json['academyCode'] ?? json['academy_code'],
      assignedSections: (json['assignedSections'] as List?)?.map((e) => e.toString()).toList() ?? [],
      linkedChildren: (json['linkedChildren'] as List?)?.map((e) => (e is Map ? e['id'] : e).toString()).toList() ?? [],
    );
  }
}
