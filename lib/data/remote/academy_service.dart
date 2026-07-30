import 'api_client.dart';

/// Backed by the Node API's `PATCH /academies/me` endpoint instead of
/// Firestore's per-user `academy_name`/`academy_address`/... fields — the
/// new backend normalizes academy branding into its own `Academy` row.
class AcademyService {
  final ApiClient _api;
  AcademyService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<void> updateMine({
    required String name,
    required String address,
    required String phone,
    String? logoUrl,
  }) async {
    await _api.patch('/academies/me', data: {
      'name': name.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
      if (logoUrl != null) 'logoUrl': logoUrl,
    });
  }
}
