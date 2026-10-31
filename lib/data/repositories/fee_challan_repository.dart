import '../models/fee_challan_model.dart';
import '../remote/api_client.dart';

class FeeChallanRepository {
  final ApiClient _api = ApiClient();
  FeeChallanRepository({dynamic db});

  Future<void> createChallan(FeeChallanModel challan) async {
    await _api.post('/fees/challans/generate', {
      'classId': challan.studentId,
      'monthlyFee': challan.monthlyFee,
      'admissionFee': challan.admissionFee,
      'examFee': challan.examFee,
      'transportFee': challan.transportFee,
      'fine': challan.fine,
      'dueDate': challan.dueDate.toIso8601String(),
    });
  }

  Future<List<FeeChallanModel>> getForStudent(String studentId, String academyId) async {
    try {
      final res = await _api.get('/fees/challans/student/$studentId');
      final list = res as List;
      return list.map((item) => FeeChallanModel.fromMap(item['id'] ?? '', item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FeeChallanModel>> getAll(String academyId) async {
    return [];
  }

  Future<FeeChallanModel?> getLatestForStudent(String studentId, String academyId, {String? month}) async {
    final list = await getForStudent(studentId, academyId);
    if (list.isEmpty) return null;
    return list.first;
  }

  Future<Map<String, FeeChallanModel?>> getLatestForStudents(List<String> studentIds, String academyId, {String? month}) async {
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
