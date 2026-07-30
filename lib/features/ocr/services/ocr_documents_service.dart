import '../../../data/remote/api_client.dart';
import '../../../data/remote/api_exception.dart';
import '../models/ocr_document_model.dart';

/// Backed by the Node API's `/ocr-documents` endpoints instead of Firestore.
/// Owner-scoped server-side (no academy filtering), matching the legacy
/// app's deliberate design — every call here implicitly means "my own
/// documents", there's no `uid` parameter to pass anymore.
class OcrDocumentsService {
  final ApiClient _api;
  OcrDocumentsService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<void> saveDocument({
    required String title,
    required String extractedText,
  }) async {
    await _api.post('/ocr-documents', data: {
      'title': title.trim(),
      'extractedText': extractedText.trim(),
    });
  }

  /// No push channel exists server-side, so this is a one-shot fetch
  /// wrapped in a single-emission `Stream` — every existing `StreamBuilder`
  /// call site keeps compiling and working, just without live updates.
  Stream<List<OcrDocumentModel>> getDocuments() =>
      Stream.fromFuture(_fetchAll());

  Future<List<OcrDocumentModel>> _fetchAll() async {
    final response =
        await _api.get('/ocr-documents', queryParameters: {'limit': 100});
    final items = response.data['data'] as List<dynamic>;
    return items
        .map((d) => OcrDocumentModel.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteDocument(String documentId) async {
    await _api.delete('/ocr-documents/$documentId');
  }

  Future<void> updateDocument({
    required String documentId,
    required String title,
    required String extractedText,
  }) async {
    await _api.patch('/ocr-documents/$documentId', data: {
      'title': title.trim(),
      'extractedText': extractedText.trim(),
    });
  }

  Future<OcrDocumentModel?> getDocumentById(String documentId) async {
    try {
      final response = await _api.get('/ocr-documents/$documentId');
      return OcrDocumentModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
