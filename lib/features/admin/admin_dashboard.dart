import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../logic/auth_provider.dart';
import '../../logic/member_provider.dart';
import '../../widgets/gradient_background.dart';
import 'user_management_screen.dart';
import 'approval_requests_screen.dart';
import 'fee_ledger_screen.dart';
import 'announcements_screen.dart';
import 'class_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberProvider>().load();
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.login, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final members = context.watch<MemberProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.admin_panel_settings_rounded,
                color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            Text('Admin Portal',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary),
            onPressed: _logout,
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => members.load(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Welcome, ${user?.fullName ?? 'Admin'}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Academy overview',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _statCard('Teachers', members.totalTeachers,
                        Icons.co_present_rounded),
                    const SizedBox(width: 12),
                    _statCard('Students', members.totalStudents,
                        Icons.school_rounded),
                    const SizedBox(width: 12),
                    _statCard('Parents', members.totalParents,
                        Icons.family_restroom_rounded),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('MANAGE',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                _actionTile(
                  'User Management',
                  'Add or remove teachers, students, parents',
                  Icons.group_rounded,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UserManagementScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _actionTile(
                  'Class Management',
                  'Create classes, assign teachers, enroll students',
                  Icons.class_rounded,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ClassManagementScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _actionTile(
                  'Approval Requests',
                  'Approve or reject new signups',
                  Icons.how_to_reg_rounded,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ApprovalRequestsScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _actionTile(
                  'Fee Ledger',
                  'Track fees and defaulters',
                  Icons.receipt_long_rounded,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FeeLedgerScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _actionTile(
                  'Announcements',
                  'Broadcast to teachers, students, parents',
                  Icons.campaign_rounded,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AnnouncementsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 24),
            const SizedBox(height: 8),
            Text('$value',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
      String title, String subtitle, IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (enabled)
                  const Icon(Icons.chevron_right,
                      color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}