import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/app_user.dart';
import '../data/remote/auth_service.dart';

class ParentProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  static const String _storageKey = 'linked_children_v1';

  List<AppUser> _children = [];
  bool _loading = false;

  List<AppUser> get children => _children;
  bool get loading => _loading;

  ParentProvider() {
    loadLinkedChildren();
  }

  Future<void> loadLinkedChildren() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encoded = prefs.getString(_storageKey);
      
      if (encoded != null) {
        final List<dynamic> decoded = jsonDecode(encoded);
        
        // Fetch all in parallel for speed
        final profiles = await Future.wait(
          decoded.map((item) => _authService.getProfile(item['uid']))
        );
        
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
    _loading = true;
    notifyListeners();

    try {
      final student = await _authService.findStudentByEmail(email);
      if (student == null) {
        return "No student found with this email.";
      }

      if (_children.any((c) => c.uid == student.uid)) {
        return "This child is already linked.";
      }

      _children.add(student);
      await _persist();
      return null; // Success
    } catch (e) {
      return "Linking failed: $e";
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addChild(AppUser student) async {
    if (_children.any((c) => c.uid == student.uid)) return;
    _children.add(student);
    await _persist();
    notifyListeners();
  }

  Future<void> unlinkChild(String uid) async {
    _children.removeWhere((c) => c.uid == uid);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _children.map((c) => {'uid': c.uid}).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }
}
