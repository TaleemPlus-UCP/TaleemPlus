import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() => {
        'academy_id': academyId,
        'class_id': classId,
        'teacher_id': teacherId,
        'teacher_name': teacherName,
        'title': title.trim(),
        'description': description.trim(),
        'file_url': fileUrl,
        'created_at': FieldValue.serverTimestamp(),
      };

  factory SharedResource.fromMap(String id, Map<String, dynamic> map) {
    return SharedResource(
      id: id,
      academyId: map['academy_id'] ?? '',
      classId: map['class_id'] ?? '',
      teacherId: map['teacher_id'] ?? '',
      teacherName: map['teacher_name'] ?? 'Teacher',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      fileUrl: map['file_url'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
