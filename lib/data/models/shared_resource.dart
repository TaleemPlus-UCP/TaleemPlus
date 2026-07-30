/// A note/link a teacher shared with one class offering. `classId` is the
/// offering id (the backend calls it `offeringId`, same convention as
/// `QuizModel.classId`). `fileUrl` maps to the backend's `linkUrl` — it was
/// always just a pasted link, never an uploaded file.
class SharedResource {
  final String id;
  final String academyId;
  final String classId;
  final String teacherId;
  final String teacherName;
  final String title;
  final String description;
  final String? fileUrl;
  final DateTime createdAt;

  SharedResource({
    required this.id,
    required this.academyId,
    required this.classId,
    required this.teacherId,
    required this.teacherName,
    required this.title,
    required this.description,
    this.fileUrl,
    required this.createdAt,
  });

  factory SharedResource.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'] as Map<String, dynamic>?;
    return SharedResource(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      classId: json['offeringId'] as String,
      teacherId: json['teacherId'] as String,
      teacherName: (teacher?['fullName'] as String?) ?? 'Teacher',
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      fileUrl: json['linkUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
