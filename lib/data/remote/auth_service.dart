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
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
          'Could not sign in. Check your connection and try again.');
    }
  }

  Future<AppUser?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  /// Fetches multiple user profiles in a single batch of queries instead of
  /// one `.get()` per id (used for a parent's linked children). Firestore's
  /// `whereIn` caps at 10 values, so ids are chunked.
  Future<List<AppUser>> getProfilesByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    final results = <AppUser>[];
    for (var i = 0; i < uids.length; i += 10) {
      final chunk = uids.sublist(i, i + 10 > uids.length ? uids.length : i + 10);
      final snap = await _users
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map((d) => AppUser.fromMap(d.id, d.data())));
    }
    return results;
  }

  /// Real-time view of a user's own profile document. Used to keep
  /// dependent state (e.g. a parent's `linked_children`) in sync with
  /// Firestore instead of relying on a cached snapshot taken at login.
  Stream<AppUser?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    });
  }

  /// Returns all approved users for the requested role and academy.
  /// Both fields are filtered server-side (two equality clauses, no
  /// composite index required) so this stays within the Firestore rule
  /// scoping every non-admin user to their own academy.
  Future<List<AppUser>> getApprovedByRole(
      UserRole role, String academyId) async {
    try {
      final snap = await _users
          .where('role', isEqualTo: role.name)
          .where('academy_id', isEqualTo: academyId)
          .get();

      final users = snap.docs
          .map((d) => AppUser.fromMap(d.id, d.data()))
          .where((u) => u.isApproved) // Local status check
          .toList();

      users.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return users;
    } catch (e) {
      debugPrint("Error fetching approved users: $e");
      return [];
    }
  }

  /// Returns all users of a role for an academy (server-side scoped).
  Future<List<AppUser>> getUsersByRole(UserRole role, String academyId) async {
    try {
      final snap = await _users
          .where('role', isEqualTo: role.name)
          .where('academy_id', isEqualTo: academyId)
          .get();

      final users =
          snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();

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

  /// Atomically link a child to a parent. Uses `arrayUnion` instead of
  /// reading the current list and writing the whole array back, so two
  /// devices linking different children for the same parent at the same
  /// time can't silently clobber one another's change.
  Future<void> addLinkedChild(String parentUid, String childUid) async {
    await _users.doc(parentUid).update({
      'linked_children': FieldValue.arrayUnion([childUid]),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Atomically unlink a child from a parent — see [addLinkedChild].
  Future<void> removeLinkedChild(String parentUid, String childUid) async {
    await _users.doc(parentUid).update({
      'linked_children': FieldValue.arrayRemove([childUid]),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Self-service recovery for a non-admin account that ended up scoped to
  /// the wrong academy_id (e.g. a mistyped/stale join code at signup, or an
  /// admin-created account from a different academy session) and therefore
  /// can't see announcements/data from the rest of their intended school.
  /// A user may always update their own `users/{uid}` document under the
  /// Firestore rules, so this works even though an admin from academy A can
  /// never fix a user who is mistakenly scoped to academy B.
  Future<AppUser> relinkAcademy(String uid, String code) async {
    final academy = await findAcademyByCode(code);
    if (academy == null) {
      throw AuthException('Invalid Academy Code!');
    }
    await _users.doc(uid).update({
      'academy_id': academy.uid,
      'academy_name': academy.academyName,
      'academy_address': academy.academyAddress,
      'academy_phone': academy.academyPhone,
      'updated_at': FieldValue.serverTimestamp(),
    });
    final profile = await getProfile(uid);
    if (profile == null) {
      throw AuthException('Account profile not found. Contact your admin.');
    }
    return profile;
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
      final snap = await _users
          .where('account_status', isEqualTo: 'pending')
          .where('academy_id', isEqualTo: academyId)
          .get();

      final pending =
          snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();

      pending.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return pending;
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
      'extra_info': extraInfo,
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

  /// Confirms [password] actually matches the signed-in user's real
  /// credentials, without signing them out. Used before saving a password
  /// for biometric unlock, so a mistyped password can't silently get stored.
  Future<bool> verifyPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    try {
      final cred =
          EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);
      return true;
    } on FirebaseAuthException {
      return false;
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
