import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../data/models/app_user.dart';
import '../data/remote/api_client.dart';
import '../data/remote/auth_service.dart';

enum AuthStatus { idle, loading, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    // A dead refresh token (expired/revoked/reused) surfaces here from
    // anywhere in the app, not just an explicit sign-out.
    ApiClient.instance.onSessionExpired = _handleSessionExpiredWithNotice;
  }

  AuthStatus _status = AuthStatus.idle;
  AppUser? _currentUser;
  String? _errorMessage;
  bool _pendingApproval = false;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _currentUser != null;
  bool get pendingApproval => _pendingApproval;

  /// Restores a session from the securely-stored token pair (see
  /// [TokenStorage]) instead of Firebase Auth's own persisted session.
  /// [ApiClient] transparently refreshes an expired access token using the
  /// stored refresh token, so this succeeds as long as the refresh token
  /// itself is still valid (not expired, revoked, or reused elsewhere).
  Future<AppUser?> tryRestoreSession() async {
    try {
      final profile = await _authService.getCurrentProfile();
      if (profile != null && profile.isApproved) {
        _currentUser = profile;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return _currentUser;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true only when the user is approved and should enter a dashboard.
  /// Returns false for errors OR pending approval (check [pendingApproval]).
  Future<bool> signUp({
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
    _setLoading();
    try {
      final user = await _authService.signUp(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        role: role,
        academyName: academyName,
        academyId: academyId,
        academyAddress: academyAddress,
        academyPhone: academyPhone,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );

      if (!user.isApproved) {
        _pendingApproval = true;
        _currentUser = null;
        _status = AuthStatus.idle;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _setLoading();
    try {
      _currentUser =
          await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      await _persistRememberMe(rememberMe, email);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  /// Drops local session state without an extra round-trip to `/auth/logout`,
  /// since the token is already dead server-side. Screens react to
  /// `isAuthenticated` flipping false the same way they would after an
  /// explicit [signOut].
  void handleSessionExpired() {
    if (_currentUser == null) return;
    _currentUser = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  /// Same as [handleSessionExpired], plus forces navigation to Login with a
  /// visible reason — mirrors [SessionProvider]'s own forced-sign-out UX so
  /// a dropped session is never silent, however it was detected.
  void _handleSessionExpiredWithNotice() {
    final wasAuthenticated = _currentUser != null;
    handleSessionExpired();
    if (!wasAuthenticated) return;

    final nav = rootNavigatorKey.currentState;
    nav?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
              content: Text('Your session has expired. Please log in again.')),
        );
      }
    });
  }

  Future<String?> loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(DbKeys.prefRememberMe) ?? false) {
      return prefs.getString(DbKeys.prefSavedEmail);
    }
    return null;
  }

  Future<void> _persistRememberMe(bool remember, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DbKeys.prefRememberMe, remember);
    if (remember) {
      await prefs.setString(DbKeys.prefSavedEmail, email.trim());
    } else {
      await prefs.remove(DbKeys.prefSavedEmail);
    }
  }

  /// Self-service fix for an account scoped to the wrong academy_id (see
  /// [AuthService.relinkAcademy]). Refreshes [currentUser] in place so every
  /// screen watching this provider (announcements, dashboards, etc.)
  /// immediately re-queries under the corrected academy scope.
  Future<void> relinkAcademy(String code) async {
    if (_currentUser == null) {
      throw AuthException('No active session found.');
    }
    final updated = await _authService.relinkAcademy(_currentUser!.uid, code);
    _currentUser = updated;
    notifyListeners();
  }

  void clearError() {
    if (_status == AuthStatus.error) {
      _status = AuthStatus.idle;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _pendingApproval = false;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
