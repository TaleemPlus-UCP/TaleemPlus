import 'package:flutter/foundation.dart';
import '../data/models/timetable_slot.dart';
import '../data/remote/timetable_service.dart';

/// Conflict detection (teacher/room/section double-booking) is now enforced
/// server-side — `createSlot`/`updateSlot` throw an [ApiException] with a
/// human-readable message on a 409, instead of this provider pre-checking
/// against a locally fetched day's slots.
class TimetableProvider extends ChangeNotifier {
  final TimetableService _service = TimetableService();
  bool _loading = false;

  bool get loading => _loading;

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  Future<void> createSlot(TimetableSlot slot) async {
    _setLoading(true);
    try {
      await _service.createSlot(slot);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSlot(TimetableSlot slot) async {
    _setLoading(true);
    try {
      await _service.updateSlot(slot);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSlot(String id) async {
    _setLoading(true);
    try {
      await _service.deleteSlot(id);
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<TimetableSlot>> watchAll(String academyId) =>
      _service.watchAll(academyId);

  Stream<List<TimetableSlot>> watchForTeacher(
          String teacherId, String academyId) =>
      _service.watchForTeacher(teacherId, academyId);

  Stream<List<TimetableSlot>> watchForClassIds(
          List<String> classIds, String academyId) =>
      _service.watchForClassIds(classIds, academyId);

  Stream<List<TimetableSlot>> watchForStudent(String studentId) =>
      _service.watchForStudent(studentId);
}
