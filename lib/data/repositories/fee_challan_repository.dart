import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_challan_model.dart';

class FeeChallanRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('fee_challans');

  Future<void> createChallan(FeeChallanModel challan) async {
    await _col.doc(challan.id).set(challan.toMap());
  }

  /// Sorting phone pe (client-side) — Firestore index ki zaroorat nahi.
  Future<List<FeeChallanModel>> getForStudent(
      String studentId, String academyId) async {
    final snap = await _col
        .where('academy_id', isEqualTo: academyId)
        .where('student_id', isEqualTo: studentId)
        .get();

    final list = snap.docs
        .map((doc) =>
            FeeChallanModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    _sortNewestFirst(list);
    return list;
  }

  /// Sorting client-side — no index needed.
  Future<List<FeeChallanModel>> getAll(String academyId) async {
    final snap = await _col.where('academy_id', isEqualTo: academyId).get();
    final list = snap.docs
        .map((doc) =>
            FeeChallanModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    _sortNewestFirst(list);
    return list;
  }

  /// Month filter + latest — dono phone pe. No index needed.
  Future<FeeChallanModel?> getLatestForStudent(
      String studentId, String academyId,
      {String? month}) async {
    final snap = await _col
        .where('academy_id', isEqualTo: academyId)
        .where('student_id', isEqualTo: studentId)
        .get();

    var list = snap.docs
        .map((doc) =>
            FeeChallanModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    // Month filter client-side (challan_number "CH-JUL..." pattern se)
    if (month != null && month.length >= 3) {
      final prefix = "CH-${month.substring(0, 3).toUpperCase()}";
      list = list.where((c) => c.challanNumber.startsWith(prefix)).toList();
    }

    if (list.isEmpty) return null;
    _sortNewestFirst(list);
    return list.first;
  }

  /// Batched version of [getLatestForStudent] for a whole class roster —
  /// one `whereIn` query per 10 students instead of one query per student,
  /// so a class fee-status screen doesn't fire N separate reads for N rows.
  Future<Map<String, FeeChallanModel?>> getLatestForStudents(
      List<String> studentIds, String academyId,
      {String? month}) async {
    final result = <String, FeeChallanModel?>{
      for (final id in studentIds) id: null,
    };
    if (studentIds.isEmpty) return result;

    final prefix = (month != null && month.length >= 3)
        ? "CH-${month.substring(0, 3).toUpperCase()}"
        : null;

    for (var i = 0; i < studentIds.length; i += 10) {
      final chunk =
          studentIds.sublist(i, i + 10 > studentIds.length ? studentIds.length : i + 10);
      final snap = await _col
          .where('academy_id', isEqualTo: academyId)
          .where('student_id', whereIn: chunk)
          .get();

      final list = snap.docs
          .map((doc) => FeeChallanModel.fromMap(
              doc.id, doc.data() as Map<String, dynamic>))
          .where((c) => prefix == null || c.challanNumber.startsWith(prefix))
          .toList();
      _sortNewestFirst(list);

      for (final challan in list) {
        // Newest-first, so only keep the first (latest) challan seen per
        // student.
        result[challan.studentId] ??= challan;
      }
    }
    return result;
  }

  Future<void> updateStatus(String id, String status) async {
    await _col.doc(id).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Newest first
  void _sortNewestFirst(List<FeeChallanModel> list) {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
