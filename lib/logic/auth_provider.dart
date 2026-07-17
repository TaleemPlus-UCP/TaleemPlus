import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../data/models/app_user.dart';
import '../data/remote/auth_service.dart';

enum AuthStatus { idle, loading, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

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

  Future<AppUser?> tryRestoreSession() async {
    final fbUser = _authService.firebaseUser;
    if (fbUser == null) return null;
    try {
      final profile = await _authService.getProfile(fbUser.uid);
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
  }) async {
    _setLoading();
    try {
      final user = await _authService.signUp(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        role: role,
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