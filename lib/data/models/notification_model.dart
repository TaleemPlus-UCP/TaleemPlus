import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String academyId;
  final String recipientId; // UID of the user who should see this
  final String title;
  final String message;
  final String
      type; // 'approval', 'fee', 'attendance', 'result', 'announcement'
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.academyId,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'academy_id': academyId,
      'recipient_id': recipientId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      academyId: map['academy_id'] ?? '',
      recipientId: map['recipient_id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      isRead: map['is_read'] ?? false,
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }
}
