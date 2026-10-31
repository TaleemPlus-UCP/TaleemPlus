import '../models/fee_challan_model.dart';
import '../remote/api_client.dart';

class FeeChallanRepository {
  final ApiClient _api = ApiClient();
  FeeChallanRepository({dynamic db});

  Future<void> createChallan(FeeChallanModel challan) async {
    await _api.post('/fees/challans', {
      'studentId': challan.studentId,
      'classLabel': challan.classLabel,
      'rollNumber': challan.rollNumber,
      'monthlyFee': challan.monthlyFee,
      'admissionFee': challan.admissionFee,
      'examFee': challan.examFee,
      'transportFee': challan.transportFee,
      'fine': challan.fine,
      'dueDate': challan.dueDate.toIso8601String(),
      'billingPeriod': challan.billingPeriod,
    });
  }

  Future<List<FeeChallanModel>> getForStudent(
      String studentId, String academyId) async {
    try {
      final res = await _api.get('/fees/challans/student/$studentId');
      final list = res as List;
      return list
          .map((item) => FeeChallanModel.fromMap(item['id'] ?? '', item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FeeChallanModel>> getAll(String academyId) async {
    final response = await _api.get('/fees/challans');
    return (response as List)
        .map((item) => FeeChallanModel.fromMap(item['id'] ?? '', item))
        .toList();
  }

  Future<FeeChallanModel?> getLatestForStudent(
      String studentId, String academyId,
      {String? month}) async {
    final list = await getForStudent(studentId, academyId);
    if (list.isEmpty) return null;
    if (month == null || month.isEmpty) return list.first;
    final target = month.contains('-')
        ? month
        : '${DateTime.now().year}-${_monthNumber(month)}';
    final matches = list.where((challan) => challan.billingPeriod == target);
    return matches.isEmpty ? null : matches.first;
  }

  String _monthNumber(String month) {
    const months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    final index = months.indexOf(month.toLowerCase());
    return index < 0 ? '00' : (index + 1).toString().padLeft(2, '0');
  }

  Future<Map<String, FeeChallanModel?>> getLatestForStudents(
      List<String> studentIds, String academyId,
      {String? month}) async {
    final result = <String, FeeChallanModel?>{};
    for (final id in studentIds) {
      result[id] = await getLatestForStudent(id, academyId, month: month);
    }
    return result;
  }

  Future<void> updateStatus(String id, String status) async {
    if (status.toLowerCase() == 'paid') {
      await _api.put('/fees/challans/$id/pay', {});
    }
  }
}
