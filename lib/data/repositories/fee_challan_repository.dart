import '../../data/remote/api_client.dart';
import '../models/fee_challan_model.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Backed by the Node API's `/fee-challans` endpoints instead of Firestore.
class FeeChallanRepository {
  final ApiClient _api;
  FeeChallanRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  /// One ad-hoc challan for a single student (e.g. a one-off fine), separate
  /// from section-wide billing. See [generateForSection] for that.
  Future<FeeChallanModel> createSingle({
    required String studentId,
    required int billingYear,
    required int billingMonth,
    required double monthlyFee,
    double admissionFee = 0,
    double examFee = 0,
    double transportFee = 0,
    double fine = 0,
    DateTime? dueDate,
  }) async {
    final response = await _api.post('/fee-challans', data: {
      'studentId': studentId,
      'billingYear': billingYear,
      'billingMonth': billingMonth,
      'monthlyFee': monthlyFee,
      'admissionFee': admissionFee,
      'examFee': examFee,
      'transportFee': transportFee,
      'fine': fine,
      if (dueDate != null) 'dueDate': _dateOnly(dueDate),
    });
    return FeeChallanModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Batch-generates a challan for every ACTIVE student enrolled in
  /// [sectionId]; students already billed for that month are skipped
  /// server-side. Returns `{generatedCount, skippedCount, eligibleCount}`.
  Future<Map<String, dynamic>> generateForSection({
    required String sectionId,
    required int billingYear,
    required int billingMonth,
    required double monthlyFee,
    double admissionFee = 0,
    double examFee = 0,
    double transportFee = 0,
    double fine = 0,
    DateTime? dueDate,
  }) async {
    final response = await _api.post('/fee-challans/generate', data: {
      'sectionId': sectionId,
      'billingYear': billingYear,
      'billingMonth': billingMonth,
      'monthlyFee': monthlyFee,
      'admissionFee': admissionFee,
      'examFee': examFee,
      'transportFee': transportFee,
      'fine': fine,
      if (dueDate != null) 'dueDate': _dateOnly(dueDate),
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<FeeChallanModel>> getForStudent(
      String studentId, String academyId) async {
    final response = await _api.get('/fee-challans',
        queryParameters: {'studentId': studentId, 'limit': 100});
    final list = _parseList(response.data['data'] as List<dynamic>);
    _sortNewestFirst(list);
    return list;
  }

  /// Admin: every challan in the academy.
  Future<List<FeeChallanModel>> getAll(String academyId) async {
    final response =
        await _api.get('/fee-challans', queryParameters: {'limit': 200});
    final list = _parseList(response.data['data'] as List<dynamic>);
    _sortNewestFirst(list);
    return list;
  }

  /// [month] is a month NAME (e.g. "July"); the current year is assumed,
  /// matching the rest of the app's convention (there is no year selector).
  Future<FeeChallanModel?> getLatestForStudent(
      String studentId, String academyId,
      {String? month}) async {
    final query = <String, dynamic>{'studentId': studentId, 'limit': 1};
    final monthIndex = month != null ? _monthNames.indexOf(month) + 1 : 0;
    if (monthIndex > 0) {
      query['billingYear'] = DateTime.now().year;
      query['billingMonth'] = monthIndex;
    }
    final response = await _api.get('/fee-challans', queryParameters: query);
    final list = _parseList(response.data['data'] as List<dynamic>);
    if (list.isEmpty) return null;
    _sortNewestFirst(list);
    return list.first;
  }

  /// Fee status for every student enrolled in [sectionId] for one month, via
  /// a single roster call instead of one query per student.
  Future<Map<String, FeeChallanModel?>> getSectionStatus(String sectionId,
      {String? month}) async {
    final query = <String, dynamic>{};
    final monthIndex = month != null ? _monthNames.indexOf(month) + 1 : 0;
    if (monthIndex > 0) {
      query['year'] = DateTime.now().year;
      query['month'] = monthIndex;
    }
    final response = await _api.get('/fee-challans/sections/$sectionId/status',
        queryParameters: query);
    final students = (response.data['data'] as Map<String, dynamic>)['students']
        as List<dynamic>;
    return {
      for (final s in students)
        (s as Map<String, dynamic>)['studentId'] as String: s['challan'] != null
            ? FeeChallanModel.fromJson(s['challan'] as Map<String, dynamic>)
            : null,
    };
  }

  Future<void> updateStatus(String id, String status) async {
    await _api.patch('/fee-challans/$id/status',
        data: {'status': status.toUpperCase()});
  }

  List<FeeChallanModel> _parseList(List<dynamic> items) => items
      .map((c) => FeeChallanModel.fromJson(c as Map<String, dynamic>))
      .toList();

  void _sortNewestFirst(List<FeeChallanModel> list) {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static String _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);
}
