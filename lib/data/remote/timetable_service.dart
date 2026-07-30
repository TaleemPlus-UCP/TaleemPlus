import 'api_client.dart';
import '../models/timetable_slot.dart';

/// Backed by the Node API's `/timetable` endpoints instead of Firestore.
///
/// The backend scopes `GET /timetable` by the caller's own JWT role — admin
/// gets the whole academy, teacher gets their own slots, student gets their
/// enrolled sections — so `watchAll`/`watchForTeacher`/`watchForClassIds`
/// need no scoping params beyond who's asking; they're kept only so their
/// call sites don't need to change. A parent viewing a specific child must
/// still pass that child's id explicitly (see [watchForStudent]), since the
/// backend can't infer which linked child is meant.
class TimetableService {
  final ApiClient _api;
  TimetableService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<TimetableSlot> createSlot(TimetableSlot slot) async {
    final response = await _api.post('/timetable', data: slot.toJson());
    return TimetableSlot.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<TimetableSlot> updateSlot(TimetableSlot slot) async {
    final response =
        await _api.patch('/timetable/${slot.id}', data: slot.toJson());
    return TimetableSlot.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteSlot(String id) async {
    await _api.delete('/timetable/$id');
  }

  Future<List<TimetableSlot>> _fetchMine() async {
    final response = await _api.get('/timetable');
    final items = response.data['data'] as List<dynamic>;
    final list = items
        .map((s) => TimetableSlot.fromJson(s as Map<String, dynamic>))
        .toList();
    _sortByDayThenTime(list);
    return list;
  }

  /// Admin: every slot in the academy.
  Stream<List<TimetableSlot>> watchAll(String academyId) =>
      Stream.fromFuture(_fetchMine());

  /// Teacher: only their own assigned slots.
  Stream<List<TimetableSlot>> watchForTeacher(
          String teacherId, String academyId) =>
      Stream.fromFuture(_fetchMine());

  /// Student: their own enrolled sections' slots.
  Stream<List<TimetableSlot>> watchForClassIds(
          List<String> classIds, String academyId) =>
      Stream.fromFuture(_fetchMine());

  /// Parent: a specific linked child's timetable.
  Stream<List<TimetableSlot>> watchForStudent(String studentId) {
    return Stream.fromFuture(() async {
      final response = await _api
          .get('/timetable', queryParameters: {'studentId': studentId});
      final items = response.data['data'] as List<dynamic>;
      final list = items
          .map((s) => TimetableSlot.fromJson(s as Map<String, dynamic>))
          .toList();
      _sortByDayThenTime(list);
      return list;
    }());
  }

  void _sortByDayThenTime(List<TimetableSlot> list) {
    list.sort((a, b) {
      final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayCompare != 0) return dayCompare;
      return a.startMinutes.compareTo(b.startMinutes);
    });
  }
}
