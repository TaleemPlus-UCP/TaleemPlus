import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_user.dart';

/// Thrown for any auth-related failure with a user-friendly message.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Handles all Firebase Auth + Firestore user-profile operations.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(DbKeys.usersCollection);

  User? get firebaseUser => _auth.currentUser;

  /// Registers a new account and writes the profile (incl. role) to Firestore.
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;
      final user = AppUser(
        uid: uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        role: role,
        accountStatus: 'active',
        createdAt: DateTime.now(),
      );

      await _users.doc(uid).set(user.toMap());
      await cred.user!.updateDisplayName(fullName.trim());
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (_) {
      throw AuthException('Something went wrong. Please try again.');
    }
  }

  /// Signs in and returns the full profile (with role) from Firestore.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final profile = await getProfile(cred.user!.uid);
      if (profile == null) {
        throw AuthException('Account profile not found. Contact your admin.');
      }
      if (!profile.isActive) {
        await signOut();
        throw AuthException('This account is suspended. Contact your admin.');
      }
      return profile;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  Future<AppUser?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid credentials. Check your email and password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
