import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/models/app_user.dart';
import '../data/remote/auth_service.dart';

class ParentProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  List<AppUser> _children = [];
  bool _loading = false;
  String? _parentUid;
  String? _academyId;
  List<String> _lastChildUids = [];
  StreamSubscription<AppUser?>? _profileSub;

  List<AppUser> get children => _children;
  bool get loading => _loading;

  /// Binds this provider to the given logged-in parent. Subscribes to a
  /// real-time listener on the parent's own profile document so that
  /// `linked_children` writes (from this device or any other) are reflected
  /// immediately, and survive refreshes/app restarts without depending on a
  /// stale cached [AppUser] snapshot taken at login.
  Future<void> syncWithUser(AppUser? parent) async {
    if (parent == null || parent.role != UserRole.parent) {
      await _profileSub?.cancel();
      _profileSub = null;
      _parentUid = null;
      _academyId = null;
      _lastChildUids = [];
      _children = [];
      notifyListeners();
      return;
    }

    _academyId = parent.academyId;

    // Already listening for this parent: the live subscription already has
    // the latest data, nothing further to do on refresh/rebuild.
    if (_parentUid == parent.uid && _profileSub != null) return;

    await _profileSub?.cancel();
    _parentUid = parent.uid;
    _loading = true;
    notifyListeners();

    final completer = Completer<void>();
    _profileSub = _authService.watchProfile(parent.uid).listen(
      (profile) {
        _onProfileUpdate(profile);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (e) {
        debugPrint("Error watching parent profile: $e");
        _loading = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
    );

    // Let the dashboard's RefreshIndicator resolve once the first snapshot
    // (cache or server) has been applied.
    await completer.future;
  }

  Future<void> _onProfileUpdate(AppUser? profile) async {
    if (profile == null) {
      _children = [];
      _lastChildUids = [];
      _loading = false;
      notifyListeners();
      return;
    }

    _academyId = profile.academyId;
    final childUids = profile.linkedChildren;

    // Avoid refetching every linked child's profile when an unrelated field
    // on the parent's own document changes (e.g. updated_at).
    if (_listEquals(childUids, _lastChildUids)) {
      _loading = false;
      notifyListeners();
      return;
    }
    _lastChildUids = List<String>.from(childUids);

    _loading = true;
    notifyListeners();
    try {
      if (childUids.isEmpty) {
        _children = [];
      } else {
        _children = await _authService.getProfilesByIds(childUids);
      }
    } catch (e) {
      debugPrint("Error loading children: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<String?> linkChild(String email) async {
    if (_parentUid == null || _academyId == null) {
      return "User session expired.";
    }

    try {
      final student = await _authService.findStudentByEmail(email, _academyId!);
      if (student == null) {
        return "No student found with this email in your academy.";
      }

      if (_children.any((c) => c.uid == student.uid)) {
        return "This child is already linked.";
      }

      // The live profile listener will pick this write up and refresh
      // `_children`; no need to mutate local state here.
      await _authService.addLinkedChild(_parentUid!, student.uid);
      return null; // Success
    } catch (e) {
      return "Linking failed: $e";
    }
  }

  Future<void> addChild(AppUser student) async {
    if (_parentUid == null) return;
    if (_children.any((c) => c.uid == student.uid)) return;

    // The live profile listener will pick this write up and refresh
    // `_children`; no need to mutate local state here.
    await _authService.addLinkedChild(_parentUid!, student.uid);
  }

  Future<void> unlinkChild(String uid) async {
    if (_parentUid == null) return;
    // The live profile listener will pick this write up and refresh
    // `_children`; no need to mutate local state here.
    await _authService.removeLinkedChild(_parentUid!, uid);
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}
