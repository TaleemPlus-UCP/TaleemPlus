import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
    String? academyName,
    String? academyId,
    String? academyAddress,
    String? academyPhone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;
      final status = role == UserRole.admin ? 'active' : 'pending';

      // For Admins, we generate a short human-friendly code (e.g. TP-XXXXX)
      String? academyCode;
      if (role == UserRole.admin) {
        academyCode = "TP-${uid.substring(0, 5).toUpperCase()}";
      }

      final effectiveAcademyId = role == UserRole.admin ? uid : academyId;

      final user = AppUser(
        uid: uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        role: role,
        accountStatus: status,
        academyName: academyName,
        academyId: effectiveAcademyId,
        academyAddress: academyAddress,
        academyPhone: academyPhone,
        academyCode: academyCode,
        createdAt: DateTime.now(),
        joiningDate: DateTime.now(),
      );

      await _users.doc(uid).set(user.toMap());
      await cred.user!.updateDisplayName(fullName.trim());

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

  /// Returns all approved users for the requested role and academy.
  /// Uses broad search + local filtering to avoid Firestore index requirements.
  Future<List<AppUser>> getApprovedByRole(
      UserRole role, String academyId) async {
    try {
      // Fetch only by role to minimize index needs
      final snap = await _users.where('role', isEqualTo: role.name).get();

      final users = snap.docs
          .map((d) => AppUser.fromMap(d.id, d.data()))
          .where((u) => u.isApproved) // Local status check
          .where((u) =>
              u.academyId == academyId ||
              u.academyId == null ||
              u.academyId!.isEmpty)
          .toList();

      users.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return users;
    } catch (e) {
      debugPrint("Error fetching approved users: $e");
      return [];
    }
  }

  /// Returns all users of a role for an academy (Safe query).
  Future<List<AppUser>> getUsersByRole(UserRole role, String academyId) async {
    try {
      final snap = await _users.where('role', isEqualTo: role.name).get();

      final users = snap.docs
          .map((d) => AppUser.fromMap(d.id, d.data()))
          .where((u) =>
              u.academyId == academyId ||
              u.academyId == null ||
              u.academyId!.isEmpty)
          .toList();

      users.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return users;
    } catch (e) {
      debugPrint("Error fetching users by role: $e");
      return [];
    }
  }

  /// NEW: Find a specific student by email in a specific academy
  Future<AppUser?> findStudentByEmail(String email, String academyId) async {
    final snap = await _users
        .where('role', isEqualTo: UserRole.student.name)
        .where('email', isEqualTo: email.trim().toLowerCase())
        .where('academy_id', isEqualTo: academyId) // MUST BE SAME ACADEMY
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return AppUser.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  /// NEW: Robust search for Parent Portal (restricted by academy)
  Future<List<AppUser>> searchStudentsByName(
      String query, String academyId) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    try {
      // Use single where to avoid composite index requirement
      final snap = await _users.where('academy_id', isEqualTo: academyId).get();

      final users = snap.docs
          .map((d) => AppUser.fromMap(d.id, d.data()))
          .where((u) => u.role == UserRole.student) // Local role check
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q))
          .toList();

      return users;
    } catch (e) {
      debugPrint("Institutional search error: $e");
      return [];
    }
  }

  /// Update the list of children linked to a parent
  Future<void> updateParentChildren(
      String parentUid, List<String> childUids) async {
    await _users.doc(parentUid).update({
      'linked_children': childUids,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Find an academy by its human-friendly code (TP-XXXXX)
  Future<AppUser?> findAcademyByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;

    try {
      final snap = await _users.where('role', isEqualTo: 'admin').get();

      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['academy_code'] == cleanCode) {
          return AppUser.fromMap(doc.id, data);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Academy lookup error: $e");
      return null;
    }
  }

  // ---------- Admin approval APIs ----------

  Future<List<AppUser>> getPendingUsers(String academyId) async {
    try {
      final snap =
          await _users.where('account_status', isEqualTo: 'pending').get();

      final List<AppUser> allPending =
          snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();

      final filtered = allPending
          .where((u) =>
              u.academyId == academyId ||
              u.academyId == null ||
              u.academyId!.isEmpty)
          .toList();

      filtered.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return filtered;
    } catch (e) {
      debugPrint("Error fetching pending users: $e");
      return [];
    }
  }

  Future<void> approveUser(String uid, String academyId) async {
    await _users.doc(uid).update({
      'account_status': 'active',
      'academy_id': academyId,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectUser(String uid) => _setStatus(uid, 'rejected');

  Future<void> _setStatus(String uid, String status) async {
    await _users.doc(uid).update({
      'account_status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: update academy profile including logo
  Future<void> updateAcademyProfile({
    required String uid,
    required String name,
    required String address,
    required String phone,
    String? logoUrl,
  }) async {
    await _users.doc(uid).update({
      'academy_name': name.trim(),
      'academy_address': address.trim(),
      'academy_phone': phone.trim(),
      if (logoUrl != null) 'academy_logo': logoUrl,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: update user profile details including sections and joining date
  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    String? extraInfo,
    DateTime? joiningDate,
    List<String>? sections,
  }) async {
    await _users.doc(uid).update({
      'full_name': fullName.trim(),
      'phone_number': phoneNumber.trim(),
      'academy_name': extraInfo,
      if (joiningDate != null) 'joining_date': Timestamp.fromDate(joiningDate),
      if (sections != null) 'sections': sections,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() => _auth.signOut();

  /// Admin creates a user directly (Auto-Approved).
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
    final cleanEmail = email.trim().toLowerCase();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final uid = cred.user!.uid;

      final user = AppUser(
        uid: uid,
        fullName: fullName.trim(),
        email: cleanEmail,
        phoneNumber: phoneNumber.trim(),
        role: role,
        accountStatus: 'active',
        academyName: extraInfo,
        academyId: academyId,
        createdAt: DateTime.now(),
        joiningDate: joiningDate ?? DateTime.now(),
        assignedSections: sections ?? [],
      );

      await _users.doc(uid).set(user.toMap());
      await cred.user!.updateDisplayName(fullName.trim());

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  Future<void> directUpdatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw AuthException("No active session found.");
      }
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
