import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Handles Firebase Auth + Firestore user profiles and admin approvals.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(DbKeys.usersCollection);

  User? get firebaseUser => _auth.currentUser;

  /// Admins are auto-approved; everyone else starts as 'pending'.
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
    String? academyName, // Added
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;
      final status = role == UserRole.admin ? 'active' : 'pending';

      final user = AppUser(
        uid: uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        role: role,
        accountStatus: status,
        academyName: academyName, // Added
        createdAt: DateTime.now(),
      );

      await _users.doc(uid).set(user.toMap());
      await cred.user!.updateDisplayName(fullName.trim());

      // Pending users must not stay logged in until approved.
      if (!user.isApproved) {
        await _auth.signOut();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (_) {
      throw AuthException('Something went wrong. Please try again.');
    }
  }

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
      if (profile.isPending) {
        await signOut();
        throw AuthException('Your account is pending admin approval.');
      }
      if (profile.isRejected) {
        await signOut();
        throw AuthException(
            'Your account request was rejected. Contact your admin.');
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
  /// Returns all approved users for the requested role.
  Future<List<AppUser>> getApprovedByRole(UserRole role) async {
    final snap = await _users
        .where('role', isEqualTo: role.name)
        .where('account_status', isEqualTo: 'active')
        .get();

    final users =
    snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();

    users.sort(
          (a, b) => a.fullName.toLowerCase().compareTo(
        b.fullName.toLowerCase(),
      ),
    );

    return users;
  }

  /// Returns all users of a role (approved + pending + rejected).
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    final snap = await _users
        .where('role', isEqualTo: role.name)
        .get();

    final users =
    snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();

    users.sort(
          (a, b) => a.fullName.toLowerCase().compareTo(
        b.fullName.toLowerCase(),
      ),
    );

    return users;
  }
  // ---------- Admin approval APIs ----------

  Future<List<AppUser>> getPendingUsers() async {
    final snap =
    await _users.where('account_status', isEqualTo: 'pending').get();
    return snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
  }

  Future<void> approveUser(String uid) => _setStatus(uid, 'active');
  Future<void> rejectUser(String uid) => _setStatus(uid, 'rejected');

  Future<void> _setStatus(String uid, String status) async {
    await _users.doc(uid).update({
      'account_status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
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