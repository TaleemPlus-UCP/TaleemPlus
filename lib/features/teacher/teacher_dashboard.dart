import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../logic/auth_provider.dart';
import '../../widgets/gradient_background.dart';
import '../ocr/screens/ocr_history_screen.dart';
import '../ocr/screens/ocr_scanner_screen.dart';
import '../quiz/screens/monthly_report_screen.dart'; // NEW
import '../quiz/screens/teacher_quiz_list_screen.dart'; // NEW
import 'teacher_classes_screen.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.login, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.co_present_rounded,
                color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            const Text('Teacher Portal',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Welcome, ${user?.fullName ?? 'Teacher'}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Your classroom overview',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              const Text('MODULES',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Attendance',
                'Mark daily attendance for your classes',
                Icons.fact_check_rounded,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TeacherClassesScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'OCR Document Scanner',
                'Scan and manage digitized notes',
                Icons.document_scanner_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OcrScannerScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'OCR History',
                'View and edit previously scanned documents',
                Icons.history_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OcrHistoryScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Grading & Marks Entry',
                'Enter marks for conducted tests',
                Icons.add_chart_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherQuizListScreen(isAiGen: false)),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'AI Test Paper Generator',
                'Generate and print monthly tests',
                Icons.auto_awesome_motion_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherQuizListScreen(isAiGen: true)),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Monthly Performance',
                'View compiled student results',
                Icons.insights_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      VoidCallback? onTap,
      ) {
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