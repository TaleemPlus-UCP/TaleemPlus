import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/models/academy_member.dart';
import '../data/repositories/member_repository.dart';

class MemberProvider extends ChangeNotifier {
  final MemberRepository _repo;
  final _uuid = const Uuid();

  MemberProvider({MemberRepository? repo})
      : _repo = repo ?? MemberRepository();

  List<AcademyMember> _members = [];
  Map<String, int> _counts = {'teacher': 0, 'student': 0, 'parent': 0};
  bool _loading = false;

  List<AcademyMember> get members => _members;
  Map<String, int> get counts => _counts;
  bool get loading => _loading;

  int get totalTeachers => _counts['teacher'] ?? 0;
  int get totalStudents => _counts['student'] ?? 0;
  int get totalParents => _counts['parent'] ?? 0;

  List<AcademyMember> byRole(String role) =>
      _members.where((m) => m.role == role).toList();

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _members = await _repo.getAll();
    _counts = await _repo.counts();
    _loading = false;
    notifyListeners();
  }

  Future<void> addMember({
    required String fullName,
    required String email,
    required String phone,
    required String role,
    String extra = '',
  }) async {
    final member = AcademyMember(
      id: _uuid.v4(),
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      extra: extra.trim(),
      createdAt: DateTime.now(),
    );
    await _repo.add(member);
    await load();
  }

  Future<void> removeMember(String id) async {
    await _repo.delete(id);
    await load();
  }
}