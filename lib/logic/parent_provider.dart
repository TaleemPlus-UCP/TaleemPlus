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

  List<AppUser> get children => _children;
  bool get loading => _loading;

  /// Sync provider with current logged-in parent
  Future<void> syncWithUser(AppUser? parent) async {
    if (parent == null || parent.role != UserRole.parent) {
      _parentUid = null;
      _academyId = null;
      _children = [];
      notifyListeners();
      return;
    }

    _parentUid = parent.uid;
    _academyId = parent.academyId;
    await loadLinkedChildren(parent);
  }

  Future<void> loadLinkedChildren(AppUser parent) async {
    _loading = true;
    notifyListeners();

    try {
      final childUids = parent.linkedChildren;
      if (childUids.isEmpty) {
        _children = [];
      } else {
        // Fetch all profiles in parallel
        final profiles = await Future.wait(
            childUids.map((uid) => _authService.getProfile(uid)));
        _children = profiles.whereType<AppUser>().toList();
      }
    } catch (e) {
      debugPrint("Error loading children: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> linkChild(String email) async {
    if (_parentUid == null || _academyId == null) {
      return "User session expired.";
    }

    _loading = true;
    notifyListeners();

    try {
      final student = await _authService.findStudentByEmail(email, _academyId!);
      if (student == null) {
        return "No student found with this email in your academy.";
      }

      if (_children.any((c) => c.uid == student.uid)) {
        return "This child is already linked.";
      }

      final updatedUids = [..._children.map((c) => c.uid), student.uid];
      await _authService.updateParentChildren(_parentUid!, updatedUids);

      _children = [..._children, student];
      return null; // Success
    } catch (e) {
      return "Linking failed: $e";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addChild(AppUser student) async {
    if (_parentUid == null) return;
    if (_children.any((c) => c.uid == student.uid)) return;

    try {
      final updatedUids = [..._children.map((c) => c.uid), student.uid];
      await _authService.updateParentChildren(_parentUid!, updatedUids);
      _children = [..._children, student];
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding child: $e");
    }
  }

  Future<void> unlinkChild(String uid) async {
    if (_parentUid == null) return;
    try {
      final updatedUids =
          _children.where((c) => c.uid != uid).map((c) => c.uid).toList();
      await _authService.updateParentChildren(_parentUid!, updatedUids);
      _children = _children.where((c) => c.uid != uid).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error unlinking child: $e");
    }
  }
}
