import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/models/academic_structure.dart';
import '../data/remote/academic_structure_service.dart';

/// Streams the academy's configurable academic structure (Matric/
/// Intermediate/etc levels + groups), replacing the old hardcoded
/// `AppClasses.all` list app-wide.
class AcademicStructureProvider extends ChangeNotifier {
  final AcademicStructureService _service;
  AcademicStructureProvider({AcademicStructureService? service})
      : _service = service ?? AcademicStructureService();

  AcademicStructure _structure = AcademicStructure.defaults;
  bool _loading = true;
  StreamSubscription<AcademicStructure>? _sub;
  String? _academyId;

  AcademicStructure get structure => _structure;
  bool get loading => _loading;
  List<String> get flatClassNames => _structure.flatClassNames;

  void listenAll(String academyId) {
    if (_academyId == academyId && _sub != null) return;
    _academyId = academyId;
    _sub?.cancel();
    _loading = true;
    // Ensure a doc exists (seeding defaults) before attaching the live
    // listener, so a brand-new academy doesn't briefly show an empty list.
    _service.getOrSeed(academyId);
    _sub = _service.watch(academyId).listen((structure) {
      _structure = structure;
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> updateStructure(AcademicStructure structure) async {
    if (_academyId == null) return;
    await _service.update(_academyId!, structure);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
