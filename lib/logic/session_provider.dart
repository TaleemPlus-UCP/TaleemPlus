import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';

class SessionProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const int _timeoutSeconds = 5 * 60; // 5 minutes
  static const String _biometricKey = 'biometric_enabled';
  static const String _savedPassKey = 'saved_pass_v1';
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  Timer? _timer;
  bool _isLocked = false;
  bool _biometricEnabled = false;
  AuthProvider? _auth;

  bool get isLocked => _isLocked;
  bool get biometricEnabled => _biometricEnabled;

  SessionProvider() {
    _loadBiometricPref();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void updateAuth(AuthProvider auth) {
    _auth = auth;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // Auto-logout when app goes to background as requested
      if (_auth != null && _auth!.isAuthenticated) {
        _auth!.signOut();
      }
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
        _handleTimeout(context, auth);
      });
    }
  }

  void _handleTimeout(BuildContext context, AuthProvider auth) {
    _isLocked = true;
    auth.signOut(); // Force logout for security as requested
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

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
    }
  }

  void stopTimer() {
    _timer?.cancel();
  }
}
