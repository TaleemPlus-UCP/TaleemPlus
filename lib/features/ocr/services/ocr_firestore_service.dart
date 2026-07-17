import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ocr_document_model.dart';

class OcrFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'ocr_documents';

  /// Saves a new scanned document to Firestore
  Future<void> saveDocument({
    required String title,
    required String extractedText,
    required String createdByUid,
    required String createdByName,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'title': title.trim(),
        'extracted_text': extractedText.trim(),
        'created_by_uid': createdByUid,
        'created_by_name': createdByName,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Firestore save failed: $e");
    }
  }

  /// Fetches all OCR documents for a specific user (Realtime, Latest first)
  Stream<List<OcrDocumentModel>> getDocuments(String uid) {
    return _firestore
        .collection(_collection)
        .where('created_by_uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OcrDocumentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Deletes a document by ID
  Future<void> deleteDocument(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).delete();
    } catch (e) {
      throw Exception("Firestore delete failed: $e");
    }
  }

  /// Updates an existing document's title or text
  Future<void> updateDocument({
    required String documentId,
    required String title,
    required String extractedText,
  }) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        'title': title.trim(),
        'extracted_text': extractedText.trim(),
      });
    } catch (e) {
      throw Exception("Firestore update failed: $e");
    }
  }

  /// Fetches a single document by ID
  Future<OcrDocumentModel?> getDocumentById(String documentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(documentId).get();
      if (!doc.exists) return null;
      return OcrDocumentModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception("Firestore fetch failed: $e");
    }
  }
}
