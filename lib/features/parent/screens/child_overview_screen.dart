import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/app_user.dart';
import '../../../widgets/gradient_background.dart';
import '../../student/screens/student_attendance_screen.dart';
import '../../quiz/screens/student_test_report_screen.dart';
import '../../student/screens/student_progress_chart_screen.dart';

import 'student_challan_screen.dart';
import 'child_alerts_screen.dart'; // NEW

class ChildOverviewScreen extends StatelessWidget {
  final AppUser child;
  const ChildOverviewScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _childProfileHeader(context),
              const SizedBox(height: 24),
              const Text('LEARNING PROGRESS',
                  style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Attendance History',
                'View daily presence records',
                Icons.fact_check_rounded,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentAttendanceScreen(studentUid: child.uid))),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Important Alerts',
                'Absence and performance notifications',
                Icons.notifications_active_rounded,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildAlertsScreen(childName: child.fullName, childUid: child.uid))),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Test Reports',
                'Check marks and subject grades',
                Icons.analytics_rounded,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentTestReportScreen(studentUid: child.uid, studentName: child.fullName))),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Performance Analytics',
                'Growth charts and trends',
                Icons.insights_rounded,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProgressChartScreen(studentUid: child.uid))),
              ),
              const SizedBox(height: 24),
              const Text('FINANCE',
                  style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Fee Statements',
                'Payment history and pending dues',
                Icons.receipt_long_rounded,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentChallanScreen(studentUid: child.uid))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _childProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: Text(child.fullName[0].toUpperCase(), style: const TextStyle(color: AppColors.accent, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.fullName, style: TextStyle(color: context.appColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                Text(child.email, style: TextStyle(color: context.appColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: context.appColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
