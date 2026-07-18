import '../constants/app_constants.dart';

/// Reusable form-field validators.
/// Return `null` when valid, or an error string when invalid.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Full name is required';
    if (v.length < 3) return 'Please enter your full name';
    return null;
  }

  /// Enforces a valid email. 
  /// (Previously forced institutional domain, now optional for flexibility)
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Login accepts email OR a unique ID, so we only check it isn't empty.
  static String? emailOrId(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email or unique ID is required';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required';
    final digits = v.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < AppRules.minPasswordLength) {
      return 'Password must be at least ${AppRules.minPasswordLength} characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }
}
