import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../logic/auth_provider.dart';
import '../../logic/session_provider.dart';
import '../../data/remote/auth_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/theme_toggle_widget.dart';
import '../../core/theme/theme_extensions.dart';
import '../quiz/screens/student_test_report_screen.dart';
import '../shared/view_announcements_screen.dart';
import 'screens/student_attendance_screen.dart';
import 'screens/student_fee_screen.dart';
import 'screens/ai_summarizer_screen.dart';
import 'screens/student_progress_chart_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

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
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text('Student Portal', 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.security_rounded, color: AppColors.accent),
            onPressed: () => _showSecuritySettings(context),
          ),
          const ThemeToggle(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Welcome, ${user?.fullName ?? 'Student'}',
                  style: TextStyle(
                      color: context.appColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Your learning progress overview',
                  style: TextStyle(color: context.appColors.textSecondary)),
              const SizedBox(height: 24),
              Text('MODULES',
                  style: TextStyle(
                      color: context.appColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'My Attendance',
                'Track your daily presence and percentage',
                Icons.fact_check_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentAttendanceScreen(studentUid: user!.uid)),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Announcements',
                'View broadcasts from your academy',
                Icons.campaign_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewAnnouncementsScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Test Reports',
                'Check your marks and performance',
                Icons.analytics_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentTestReportScreen(
                      studentUid: user!.uid,
                      studentName: user.fullName,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'AI Notes Summarizer',
                'Instantly summarize notes (100% Offline)',
                Icons.auto_awesome_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiSummarizerScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Performance Analytics',
                'Visual progress charts and trends',
                Icons.insights_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentProgressChartScreen(studentUid: user!.uid)),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Fee Status',
                'View your payment history and dues',
                Icons.receipt_long_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentFeeScreen(studentUid: user!.uid)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSecuritySettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Security Settings", style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("Enhance your account security with biometric authentication.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            StatefulBuilder(
              builder: (context, setInternalState) {
                final session = context.watch<SessionProvider>();
                return SwitchListTile(
                  title: const Text("Biometric / Face Unlock", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: const Text("Use fingerprints or face ID to log in.", style: TextStyle(fontSize: 12)),
                  value: session.biometricEnabled,
                  activeColor: AppColors.accent,
                  onChanged: (val) async {
                    if (val) {
                      final authenticated = await session.authenticateWithBiometrics();
                      if (authenticated) {
                        await session.setBiometricEnabled(true);
                      }
                    } else {
                      await session.setBiometricEnabled(false);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showChangePasswordDialog(context),
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text("Change Account Password"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                foregroundColor: AppColors.accent,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.accent)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter a new password for your account.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            LabeledField(label: "New Password", hint: "Min 6 chars", controller: passCtrl, obscure: true),
            LabeledField(label: "Confirm Password", hint: "Re-enter", controller: confirmCtrl, obscure: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              if (passCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
                return;
              }
              if (passCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimum 6 characters required!")));
                return;
              }
              try {
                await AuthService().directUpdatePassword(passCtrl.text);
                if (ctx.mounted) {
                   Navigator.pop(ctx);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully!")));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            }, 
            child: const Text("UPDATE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
                      Text(title,
                          style: TextStyle(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: context.appColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (enabled)
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
