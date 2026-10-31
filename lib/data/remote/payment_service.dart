import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';

class PaymentService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getSettings() async => Map<String, dynamic>.from(
      await _api.get('/fees/payment-settings') as Map);

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _api.put('/fees/payment-settings', settings);
  }

  Future<List<Map<String, dynamic>>> pendingProofs() async =>
      (await _api.get('/fees/payment-proofs/pending') as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

  Future<void> reviewProof(String id, {required bool verified}) async {
    await _api.put('/fees/payment-proofs/$id/review', {
      'status': verified ? 'VERIFIED' : 'REJECTED',
    });
  }

  Future<void> submitProof(String challanId, XFile image) async {
    final bytes = await image.readAsBytes();
    final name = image.name.toLowerCase();
    final mimeType = name.endsWith('.png') ? 'image/png' : 'image/jpeg';
    await _api.post('/fees/challans/$challanId/proof', {
      'mimeType': mimeType,
      'imageBase64': base64Encode(bytes),
    });
  }
}
