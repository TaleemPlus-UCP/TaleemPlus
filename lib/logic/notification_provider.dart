import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../data/remote/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void updateData(List<NotificationModel> list) {
    _notifications = list;
    _unreadCount = list.where((n) => !n.isRead).length;
    notifyListeners();
  }

  Future<void> markAsRead(String id) => _service.markAsRead(id);

  Future<void> markAllAsRead(String userId, String academyId) =>
      _service.markAllAsRead(userId, academyId);
}
