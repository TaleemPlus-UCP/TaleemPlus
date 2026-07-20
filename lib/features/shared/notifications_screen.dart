import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../logic/auth_provider.dart';
import '../../logic/notification_provider.dart';
import '../../widgets/gradient_background.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final notifProv = context.watch<NotificationProvider>();
    final list = notifProv.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        actions: [
          if (notifProv.unreadCount > 0)
            TextButton(
              onPressed: () => notifProv.markAllAsRead(user!.uid, user.academyId ?? ''),
              child: const Text("Mark all as read", style: TextStyle(color: AppColors.accent)),
            ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: list.isEmpty 
              ? _buildEmptyState() 
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final n = list[i];
                    return _notifTile(ctx, n, notifProv);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text("No notifications yet", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _notifTile(BuildContext context, dynamic n, NotificationProvider prov) {
    return InkWell(
      onTap: () => prov.markAsRead(n.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.transparent : AppColors.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: n.isRead ? AppColors.border.withValues(alpha: 0.5) : AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _colorFor(n.type).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(n.type), color: _colorFor(n.type), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(n.message, style: TextStyle(color: context.appColors.textSecondary, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(DateFormat('d MMM, h:mm a').format(n.createdAt), 
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (!n.isRead)
              const CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'approval': return Icons.verified_user_rounded;
      case 'fee': return Icons.payments_rounded;
      case 'attendance': return Icons.fact_check_rounded;
      case 'result': return Icons.analytics_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'approval': return AppColors.success;
      case 'fee': return Colors.orange;
      case 'attendance': return AppColors.accent;
      case 'result': return Colors.purple;
      default: return AppColors.textSecondary;
    }
  }
}
