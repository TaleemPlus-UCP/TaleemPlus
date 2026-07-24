import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import 'auth_provider.dart';

class SessionProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const int _timeoutSeconds = 150; // 2 minutes 30 seconds
  static const String _biometricKey = 'biometric_enabled';
  static const String _savedPassKey = 'saved_pass_v1';

  static const int _backgroundGraceSeconds = 15;

  final LocalAuthentication _localAuth = LocalAuthentication();
  Timer? _timer;
  Timer? _backgroundGraceTimer;
  bool _isLocked = false;
  bool _biometricEnabled = false;
  AuthProvider? _auth;

  /// Set while the app has deliberately launched a sub-activity (camera,
  /// gallery picker, biometric prompt) that we expect to return control to
  /// us — those all trigger [AppLifecycleState.paused] just like genuinely
  /// backgrounding the app, but should never sign the user out no matter
  /// how long the user spends framing a photo or scrolling their gallery.
  int _suppressCount = 0;

  bool get isLocked => _isLocked;
  bool get biometricEnabled => _biometricEnabled;

  SessionProvider() {
    _loadBiometricPref();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundGraceTimer?.cancel();
    super.dispose();
  }

  void updateAuth(AuthProvider auth) {
    _auth = auth;
  }

  /// Call before launching a camera/gallery/biometric sub-activity so the
  /// resulting [AppLifecycleState.paused] isn't treated as backgrounding.
  /// Always pair with [resumeBackgroundLogoutTracking] in a `finally` block.
  void suppressBackgroundLogout() {
    _suppressCount++;
    _backgroundGraceTimer?.cancel();
  }

  void resumeBackgroundLogoutTracking() {
    if (_suppressCount > 0) _suppressCount--;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_suppressCount > 0) return;
      // Auto-logout when app goes to background as requested, but only
      // after a grace period — `paused` also fires for in-app system
      // overlays (camera picker, share sheet, biometric prompt), which
      // should not sign the user out.
      _backgroundGraceTimer?.cancel();
      _backgroundGraceTimer = Timer(
        const Duration(seconds: _backgroundGraceSeconds),
        () {
          if (_auth != null && _auth!.isAuthenticated) {
            _forceSignOut(
                'You were signed out because the app was in the background.');
          }
        },
      );
    } else if (state == AppLifecycleState.resumed) {
      _backgroundGraceTimer?.cancel();
    }
  }

  Future<void> _loadBiometricPref() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool(_biometricKey) ?? false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value, {String? password}) async {
    _biometricEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);

    if (value && password != null) {
      await prefs.setString(_savedPassKey, password);
    } else if (!value) {
      await prefs.remove(_savedPassKey);
    }

    notifyListeners();
  }

  Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedPassKey);
  }

  void resetTimer(BuildContext context, AuthProvider auth) {
    _auth = auth;
    _timer?.cancel();
    if (auth.isAuthenticated) {
      _timer = Timer(const Duration(seconds: _timeoutSeconds), () {
        _handleTimeout();
      });
    }
  }

  void _handleTimeout() {
    _forceSignOut(
        'Your session has expired due to inactivity. Please log in again.');
  }

  /// Signs the user out, clears the lock flag once they land back on Login,
  /// and makes sure they actually see a screen + reason instead of silently
  /// losing their session mid-dashboard.
  void _forceSignOut(String message) {
    _isLocked = true;
    _auth?.signOut();
    notifyListeners();

    final nav = rootNavigatorKey.currentState;
    nav?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLocked = false;
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  Future<bool> authenticateWithBiometrics() async {
    suppressBackgroundLogout();
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access TaleemPlus',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint("Biometric Auth Error: $e");
      return false;
    } finally {
      resumeBackgroundLogoutTracking();
    }
  }

  void stopTimer() {
    _timer?.cancel();
  }
}
