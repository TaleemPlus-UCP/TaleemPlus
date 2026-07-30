import '../../core/constants/app_constants.dart';
import '../models/app_user.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// A pair of JWTs returned by every login/register/refresh call.
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  AuthTokens({required this.accessToken, required this.refreshToken});
}

/// Auth, session, and the admin user-directory surface, backed by the
/// Node/Express/PostgreSQL API (see `backend/`).
class AuthService {
  final ApiClient _api;

  AuthService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  AuthException _fromApiException(ApiException e) => AuthException(e.message);

  /// Admins are auto-approved and receive tokens immediately; everyone else
  /// starts 'pending' and receives none until an admin approves them.
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
    String? academyName,
    String? academyId,
    String? academyAddress,
    String? academyPhone,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'phoneNumber': phoneNumber.trim(),
        'role': role.value.toUpperCase(),
        if (role == UserRole.admin) 'academyName': academyName,
        if (role == UserRole.admin) 'academyAddress': academyAddress,
        if (role == UserRole.admin) 'academyPhone': academyPhone,
        if (role != UserRole.admin) 'academyCode': academyId,
        if (securityQuestion != null && (securityAnswer ?? '').isNotEmpty)
          'securityQuestion': securityQuestion,
        if (securityQuestion != null && (securityAnswer ?? '').isNotEmpty)
          'securityAnswer': securityAnswer,
      });

      final data = response.data['data'];
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = data['tokens'];
      if (tokens != null) {
        await TokenStorage.instance.saveTokens(
          accessToken: tokens['accessToken'] as String,
          refreshToken: tokens['refreshToken'] as String,
        );
      }
      return user;
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });

      final data = response.data['data'];
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = data['tokens'];
      await TokenStorage.instance.saveTokens(
        accessToken: tokens['accessToken'] as String,
        refreshToken: tokens['refreshToken'] as String,
      );
      return user;
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  Future<void> signOut() async {
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _api.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // Best-effort — the local session is cleared either way below.
      }
    }
    await TokenStorage.instance.clear();
  }

  /// The signed-in user's own profile, via the stored access token — used
  /// only for session restore (see [AuthProvider.tryRestoreSession]).
  /// `getProfile(uid)` below remains Firestore-based for *other* users'
  /// profiles (still needed by modules not yet migrated).
  Future<AppUser?> getCurrentProfile() async {
    final token = await TokenStorage.instance.getAccessToken();
    if (token == null) return null;
    try {
      final response = await _api.get('/auth/me');
      return AppUser.fromJson(
          response.data['data']['user'] as Map<String, dynamic>);
    } on ApiException {
      return null;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _api.post('/auth/forgot-password', data: {'email': email.trim()});
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  /// The recovery question for [email], or null if that account never set
  /// one up (e.g. an admin-created account that skipped it).
  Future<String?> getSecurityQuestion(String email) async {
    try {
      final response = await _api.get('/auth/security-question',
          queryParameters: {'email': email.trim()});
      return response.data['data']['question'] as String?;
    } on ApiException {
      return null;
    }
  }

  /// Verifies [answer] against the stored hash for [email]. False both when
  /// the answer is wrong and when no recovery record exists.
  Future<bool> verifySecurityAnswer(String email, String answer) async {
    try {
      final response = await _api.post('/auth/security-question/verify', data: {
        'email': email.trim(),
        'answer': answer,
      });
      return response.data['data']['isCorrect'] as bool? ?? false;
    } on ApiException {
      return false;
    }
  }

  /// Sets/overwrites the current signed-in user's security question. [uid]
  /// and [email] are accepted for call-site compatibility but ignored —
  /// the backend always operates on the caller's own account (from the
  /// access token), never an arbitrary uid.
  Future<void> saveSecurityQuestion({
    required String uid,
    required String email,
    required String question,
    required String answer,
  }) async {
    try {
      await _api.post('/auth/security-question',
          data: {'question': question, 'answer': answer});
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  /// Find an academy by its human-friendly code (TP-XXXXX).
  Future<AppUser?> findAcademyByCode(String code) async {
    try {
      final response = await _api.get('/auth/academy',
          queryParameters: {'code': code.trim().toUpperCase()});
      final academy = response.data['data']['academy'] as Map<String, dynamic>;
      // Adapted into an AppUser-shaped stub (uid=academy id, academyName=
      // academy name) purely so signup_screen.dart's existing "linked
      // academy" preview UI (which reads `.uid`/`.academyName`) keeps working
      // unchanged — this isn't a real user account.
      return AppUser(
        uid: academy['id'] as String,
        fullName: '',
        email: '',
        phoneNumber: '',
        role: UserRole.admin,
        academyName: academy['name'] as String?,
        academyId: academy['id'] as String?,
        academyCode: academy['code'] as String?,
        academyLogo: academy['logoUrl'] as String?,
      );
    } on ApiException {
      return null;
    }
  }

  /// Self-service recovery for a non-admin account scoped to the wrong
  /// academy_id. [uid] is accepted for call-site compatibility but ignored
  /// — always relinks the caller's own account.
  Future<AppUser> relinkAcademy(String uid, String code) async {
    try {
      final response = await _api.post('/auth/relink-academy',
          data: {'code': code.trim().toUpperCase()});
      return AppUser.fromJson(
          response.data['data']['user'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  /// Change password while signed in. Requires [currentPassword] (the
  /// legacy Firebase-backed version didn't — see auth.service.ts on the
  /// backend for why that's a deliberate hardening, not just a port).
  /// Revokes every session, including the current one — the caller signs
  /// in again with the new password afterward.
  Future<void> directUpdatePassword(
      String currentPassword, String newPassword) async {
    try {
      await _api.post('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      await TokenStorage.instance.clear();
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  // ---------- Admin user-directory (Users module) ----------

  Future<List<AppUser>> getPendingUsers(String academyId) async {
    try {
      final response =
          await _api.get('/users/pending', queryParameters: {'limit': 100});
      final items = response.data['data'] as List<dynamic>;
      return items
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .toList();
    } on ApiException {
      return [];
    }
  }

  Future<void> approveUser(String uid, String academyId) async {
    await _api.post('/users/$uid/approve');
  }

  Future<void> rejectUser(String uid) async {
    await _api.post('/users/$uid/reject');
  }

  /// Returns all ACTIVE users for the requested role and academy.
  Future<List<AppUser>> getApprovedByRole(
      UserRole role, String academyId) async {
    try {
      final response = await _api.get('/users',
          queryParameters: {'role': role.value.toUpperCase(), 'limit': 200});
      final items = response.data['data'] as List<dynamic>;
      final users = items
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .where((u) => u.isApproved)
          .toList();
      users.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return users;
    } on ApiException {
      return [];
    }
  }

  /// Returns all users of a role for an academy, any status.
  Future<List<AppUser>> getUsersByRole(UserRole role, String academyId) async {
    try {
      final response = await _api.get('/users',
          queryParameters: {'role': role.value.toUpperCase(), 'limit': 200});
      final items = response.data['data'] as List<dynamic>;
      final users = items
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .toList();
      users.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return users;
    } on ApiException {
      return [];
    }
  }

  /// Admin creates a user directly (auto-ACTIVE, no approval needed).
  Future<AppUser> adminCreateUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
    required String academyId,
    String? extraInfo,
    DateTime? joiningDate,
    List<String>? sections,
  }) async {
    try {
      final response = await _api.post('/users', data: {
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'phoneNumber': phoneNumber.trim(),
        'role': role.value.toUpperCase(),
        if (extraInfo != null) 'extraInfo': extraInfo,
        if (joiningDate != null) 'joiningDate': joiningDate.toIso8601String(),
        if (sections != null) 'assignedSections': sections,
      });
      return AppUser.fromJson(response.data['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }

  /// Admin: update user profile details including sections and joining date.
  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    String? extraInfo,
    DateTime? joiningDate,
    List<String>? sections,
  }) async {
    try {
      await _api.patch('/users/$uid', data: {
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        if (extraInfo != null) 'extraInfo': extraInfo,
        if (joiningDate != null) 'joiningDate': joiningDate.toIso8601String(),
        if (sections != null) 'assignedSections': sections,
      });
    } on ApiException catch (e) {
      throw _fromApiException(e);
    }
  }
}
