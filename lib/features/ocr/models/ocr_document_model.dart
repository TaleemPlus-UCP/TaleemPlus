import 'package:cloud_firestore/cloud_firestore.dart';

class OcrDocumentModel {
  final String id;
  final String title;
  final String extractedText;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;

  OcrDocumentModel({
    required this.id,
    required this.title,
    required this.extractedText,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
  });

  // Firestore se data map mein convert karne ke liye helper
  factory OcrDocumentModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return OcrDocumentModel(
      id: documentId,
      title: map['title'] ?? '',
      extractedText: map['extracted_text'] ?? '',
      createdByUid: map['created_by_uid'] ?? '',
      createdByName: map['created_by_name'] ?? '',
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }

  // Firestore mein data save karne ke liye map return karega
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'extracted_text': extractedText,
      'created_by_uid': createdByUid,
      'created_by_name': createdByName,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // Edit karne ke liye copyWith method
  OcrDocumentModel copyWith({
    String? title,
    String? extractedText,
  }) {
    return OcrDocumentModel(
      id: id,
      title: title ?? this.title,
      extractedText: extractedText ?? this.extractedText,
      createdByUid: createdByUid,
      createdByName: createdByName,
      createdAt: createdAt,
    );
  }
}
