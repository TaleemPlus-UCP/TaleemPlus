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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      recipientId: json['recipientId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: (json['type'] as String).toLowerCase(),
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
