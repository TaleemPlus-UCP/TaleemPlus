import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/class_report_model.dart';

class ClassReportRepository {
  final FirebaseFirestore _db;
  ClassReportRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('class_reports');

  Future<void> create(ClassReportModel report) async {
    await _col.doc(report.id).set(report.toMap());
  }

  Stream<List<ClassReportModel>> watchAll(String academyId) {
    return _col.where('academy_id', isEqualTo: academyId).snapshots().map(
        (snap) => snap.docs
            .map((d) => ClassReportModel.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt)));
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
