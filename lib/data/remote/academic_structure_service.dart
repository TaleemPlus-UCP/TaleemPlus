import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/academic_structure.dart';

/// Firestore-backed storage for each academy's configurable academic
/// structure (one doc per academy in `academy_settings/{academyId}`).
class AcademicStructureService {
  final _settings = FirebaseFirestore.instance.collection('academy_settings');

  /// Reads the academy's structure, seeding it with [AcademicStructure.defaults]
  /// on first access if no doc exists yet — safe/additive, no migration
  /// needed for existing academies.
  Future<AcademicStructure> getOrSeed(String academyId) async {
    final doc = await _settings.doc(academyId).get();
    if (doc.exists && doc.data()?['academic_structure'] != null) {
      return AcademicStructure.fromMap(
          doc.data()!['academic_structure'] as Map<String, dynamic>);
    }
    await _settings.doc(academyId).set({
      'academic_structure': AcademicStructure.defaults.toMap(),
    }, SetOptions(merge: true));
    return AcademicStructure.defaults;
  }

  Stream<AcademicStructure> watch(String academyId) {
    return _settings.doc(academyId).snapshots().map((doc) {
      final raw = doc.data()?['academic_structure'];
      if (raw == null) return AcademicStructure.defaults;
      return AcademicStructure.fromMap(raw as Map<String, dynamic>);
    });
  }

  Future<void> update(String academyId, AcademicStructure structure) async {
    await _settings.doc(academyId).set(
        {'academic_structure': structure.toMap()}, SetOptions(merge: true));
  }
}
