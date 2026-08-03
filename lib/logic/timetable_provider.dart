import 'package:flutter/foundation.dart';
import '../data/models/timetable_slot.dart';
import '../data/remote/timetable_service.dart';

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

  bool _dateRangesOverlap(
      DateTime aFrom, DateTime? aTo, DateTime bFrom, DateTime? bTo) {
    final aEnd = aTo ?? DateTime(9999);
    final bEnd = bTo ?? DateTime(9999);
    return aFrom.isBefore(bEnd.add(const Duration(days: 1))) &&
        bFrom.isBefore(aEnd.add(const Duration(days: 1)));
  }

  /// Checks whether a candidate slot would double-book a teacher, a room,
  /// or a class (matched by className+section, since two different
  /// `classId`s — one per subject — can represent the same physical group
  /// of students). Returns a human-readable conflict message, or `null` if
  /// the slot is free to save. `excludeSlotId` should be set when editing
  /// an existing slot so it doesn't conflict with itself.
  /// Teacher ids with any slot overlapping the given day/time/date-range —
  /// used to proactively filter "who's available" (e.g. hide classes whose
  /// primary teacher is already busy) instead of only rejecting a conflict
  /// after the admin has already picked one, via [findConflict].
  Future<Set<String>> busyTeacherIds({
    required String academyId,
    required int dayOfWeek,
    required int startMinutes,
    required int endMinutes,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    String? excludeSlotId,
  }) async {
    final daySlots = await _service.getSlotsForDay(academyId, dayOfWeek);
    final busy = <String>{};
    for (final s in daySlots) {
      if (s.id == excludeSlotId || s.teacherId.isEmpty) continue;

      final timeOverlap =
          startMinutes < s.endMinutes && endMinutes > s.startMinutes;
      if (!timeOverlap) continue;

      final dateOverlap = _dateRangesOverlap(
          effectiveFrom, effectiveTo, s.effectiveFrom, s.effectiveTo);
      if (!dateOverlap) continue;

      busy.add(s.teacherId);
    }
    return busy;
  }

  Future<String?> findConflict({
    required String academyId,
    required int dayOfWeek,
    required int startMinutes,
    required int endMinutes,
    required String teacherId,
    required String room,
    required String className,
    required String section,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    String? excludeSlotId,
  }) async {
    final daySlots = await _service.getSlotsForDay(academyId, dayOfWeek);

    for (final s in daySlots) {
      if (s.id == excludeSlotId) continue;

      final timeOverlap =
          startMinutes < s.endMinutes && endMinutes > s.startMinutes;
      if (!timeOverlap) continue;

      final dateOverlap = _dateRangesOverlap(
          effectiveFrom, effectiveTo, s.effectiveFrom, s.effectiveTo);
      if (!dateOverlap) continue;

      if (teacherId.isNotEmpty && s.teacherId == teacherId) {
        return 'Teacher ${s.teacherName} is already teaching '
            '${s.displayLabel} at this time (${s.timeRangeLabel}).';
      }
      if (room.trim().isNotEmpty &&
          s.room.trim().toLowerCase() == room.trim().toLowerCase()) {
        return 'Room $room is already booked for ${s.displayLabel} '
            'at this time (${s.timeRangeLabel}).';
      }
      if (!s.isBreak &&
          className.isNotEmpty &&
          s.className == className &&
          s.section == section) {
        return 'Class $className${section.isNotEmpty ? '-$section' : ''} '
            'already has a session (${s.subject}) at this time '
            '(${s.timeRangeLabel}).';
      }
    }
    return null;
  }
}
