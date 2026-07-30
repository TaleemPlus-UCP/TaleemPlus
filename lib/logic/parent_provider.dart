import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/models/app_user.dart';
import '../data/remote/parent_service.dart';

class ParentProvider extends ChangeNotifier {
  final ParentService _parentService = ParentService();
  List<AppUser> _children = [];
  bool _loading = false;
  String? _parentUid;

  List<AppUser> get children => _children;
  bool get loading => _loading;

  /// Binds this provider to the given logged-in parent and loads their
  /// linked children. No push channel exists server-side, so `addChild`/
  /// `unlinkChild` below refetch themselves after a successful write rather
  /// than relying on a live subscription.
  Future<void> syncWithUser(AppUser? parent) async {
    if (parent == null || parent.role != UserRole.parent) {
      _parentUid = null;
      _children = [];
      notifyListeners();
      return;
    }

    // Already loaded for this parent — nothing further to do on refresh/rebuild.
    if (_parentUid == parent.uid) return;
    _parentUid = parent.uid;
    await _refresh();
  }

  Future<void> _refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _children = await _parentService.getChildren();
    } catch (e) {
      debugPrint("Error loading children: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addChild(AppUser student) async {
    if (_parentUid == null) return;
    if (_children.any((c) => c.uid == student.uid)) return;

    await _parentService.linkChild(studentId: student.uid);
    await _refresh();
  }

  Future<void> unlinkChild(String uid) async {
    if (_parentUid == null) return;
    await _parentService.unlinkChild(uid);
    await _refresh();
  }
}
