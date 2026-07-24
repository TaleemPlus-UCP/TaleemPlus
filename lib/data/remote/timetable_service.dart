import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_slot.dart';

class TimetableService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('timetables');

  Future<void> createSlot(TimetableSlot slot) async {
    await _col.doc(slot.id).set(slot.toMap());
  }

  Future<void> updateSlot(TimetableSlot slot) async {
    await _col.doc(slot.id).update(slot.toMap());
  }

  Future<void> deleteSlot(String id) async {
    await _col.doc(id).delete();
  }

  /// Admin: real-time list of every slot in the academy.
  Stream<List<TimetableSlot>> watchAll(String academyId) {
    return _col.where('academy_id', isEqualTo: academyId).snapshots().map(
      (snap) {
        final list = snap.docs
            .map((doc) => TimetableSlot.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList();
        _sortByDayThenTime(list);
        return list;
      },
    );
  }

  /// Teacher: real-time list of only their own assigned slots.
  Stream<List<TimetableSlot>> watchForTeacher(
      String teacherId, String academyId) {
    return _col
        .where('academy_id', isEqualTo: academyId)
        .where('teacher_id', isEqualTo: teacherId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) =>
              TimetableSlot.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      _sortByDayThenTime(list);
      return list;
    });
  }

  /// Student/Parent: real-time list across every subject-class a student is
  /// enrolled in (each subject is a separate `classId` in this app's data
  /// model — see `ClassEntity`). Firestore's `whereIn` caps at 10 values,
  /// which comfortably covers a realistic subject count; ids beyond the
  /// cap are dropped rather than silently querying the wrong data.
  Stream<List<TimetableSlot>> watchForClassIds(
      List<String> classIds, String academyId) {
    if (classIds.isEmpty) return Stream.value([]);
    final chunk = classIds.length > 10 ? classIds.sublist(0, 10) : classIds;
    return _col
        .where('academy_id', isEqualTo: academyId)
        .where('class_id', whereIn: chunk)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) =>
              TimetableSlot.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      _sortByDayThenTime(list);
      return list;
    });
  }

  /// One-time fetch of every slot on a given day-of-week, used for conflict
  /// detection before a create/update commits.
  Future<List<TimetableSlot>> getSlotsForDay(
      String academyId, int dayOfWeek) async {
    final snap = await _col
        .where('academy_id', isEqualTo: academyId)
        .where('day_of_week', isEqualTo: dayOfWeek)
        .get();
    return snap.docs
        .map((doc) =>
            TimetableSlot.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Cascade-delete every slot referencing a class that's being removed —
  /// mirrors `ClassRepository.deleteClass`'s existing cascade into
  /// `attendance_records`.
  Future<void> deleteForClass(String classId, String academyId) async {
    final snap = await _col
        .where('academy_id', isEqualTo: academyId)
        .where('class_id', isEqualTo: classId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  void _sortByDayThenTime(List<TimetableSlot> list) {
    list.sort((a, b) {
      final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayCompare != 0) return dayCompare;
      return a.startMinutes.compareTo(b.startMinutes);
    });
  }
}
