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
    // academy_id hata diya taake composite index na banana paray.
    // studentId hamesha unique hai (Firebase UID).
    final snap = await _col
        .where('student_id', isEqualTo: studentId)
        .get();

    final list = snap.docs
        .map((doc) => FeeChallanModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    _sortNewestFirst(list);
    return list;
  }

  /// Sorting client-side — no index needed.
  Future<List<FeeChallanModel>> getAll(String academyId) async {
    final snap =
    await _col.where('academy_id', isEqualTo: academyId).get();
    final list = snap.docs
        .map((doc) => FeeChallanModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    _sortNewestFirst(list);
    return list;
  }

  /// Month filter + latest — dono phone pe. No index needed.
  Future<FeeChallanModel?> getLatestForStudent(
      String studentId, String academyId,
      {String? month}) async {
    final snap = await _col
        .where('student_id', isEqualTo: studentId)
        .get();

    var list = snap.docs
        .map((doc) => FeeChallanModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    // Month filter client-side (challan_number "CH-JUL..." pattern se)
    if (month != null && month.length >= 3) {
      final prefix = "CH-${month.substring(0, 3).toUpperCase()}";
      list = list
          .where((c) => c.challanNumber.startsWith(prefix))
          .toList();
    }

    if (list.isEmpty) return null;
    _sortNewestFirst(list);
    return list.first;
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
