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
  /// NOTE: sorting phone pe hoti hai (client-side) taake Firestore
  /// composite index ki zaroorat na pare — "requires an index" error khatam.
  Stream<List<OcrDocumentModel>> getDocuments(String uid) {
    return _firestore
        .collection(_collection)
        .where('created_by_uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return OcrDocumentModel.fromMap(doc.data(), doc.id);
      }).toList();
      // Newest first (client-side sort — no index needed)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
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
      final doc =
      await _firestore.collection(_collection).doc(documentId).get();
      if (!doc.exists) return null;
      return OcrDocumentModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception("Firestore fetch failed: $e");
    }
  }
}