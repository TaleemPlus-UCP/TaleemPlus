import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/academy_member.dart';

/// Bridges the UI and the Firestore `members` collection.
class MemberRepository {
  final FirebaseFirestore _db;
  MemberRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('academy_members');

  Future<List<AcademyMember>> getAll(String academyId) async {
    final snap = await _col
        .where('academy_id', isEqualTo: academyId)
        .get();
    
    final list = snap.docs
        .map((d) => AcademyMember.fromMap(d.id, d.data()))
        .toList();
    
    // Sort client-side
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<AcademyMember>> getByRole(String role, String academyId) async {
    final snap = await _col
        .where('academy_id', isEqualTo: academyId)
        .where('role', isEqualTo: role)
        .get();

    final list = snap.docs
        .map((d) => AcademyMember.fromMap(d.id, d.data()))
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> add(AcademyMember member) async {
    await _col.doc(member.id).set(member.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<Map<String, int>> counts(String academyId) async {
    final snap = await _col
        .where('academy_id', isEqualTo: academyId)
        .get();
    
    final result = <String, int>{'teacher': 0, 'student': 0, 'parent': 0};
    for (final doc in snap.docs) {
      final role = doc.data()['role'] as String?;
      if (role != null && result.containsKey(role)) {
        result[role] = (result[role] ?? 0) + 1;
      }
    }
    return result;
  }
}