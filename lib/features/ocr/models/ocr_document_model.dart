class OcrDocumentModel {
  final String id;
  final String title;
  final String extractedText;
  final DateTime createdAt;

  OcrDocumentModel({
    required this.id,
    required this.title,
    required this.extractedText,
    required this.createdAt,
  });

  factory OcrDocumentModel.fromJson(Map<String, dynamic> json) {
    return OcrDocumentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      extractedText: json['extractedText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  OcrDocumentModel copyWith({
    String? title,
    String? extractedText,
  }) {
    return OcrDocumentModel(
      id: id,
      title: title ?? this.title,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt,
    );
  }
}
