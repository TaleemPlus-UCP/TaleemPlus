import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../logic/auth_provider.dart';
import '../../logic/session_provider.dart';
import '../../data/remote/auth_service.dart';
import '../../data/remote/notification_service.dart'; // NEW
import '../../widgets/app_widgets.dart';
import '../shared/notifications_screen.dart'; // NEW
import '../../widgets/gradient_background.dart';
import '../../widgets/theme_toggle_widget.dart'; // NEW
import '../../core/theme/theme_extensions.dart'; // NEW
import '../ocr/screens/ocr_history_screen.dart';
import '../ocr/screens/ocr_scanner_screen.dart';
import '../quiz/screens/monthly_report_screen.dart';
import '../quiz/screens/teacher_quiz_list_screen.dart';
import '../shared/view_announcements_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_announcements_screen.dart'; // NEW
import '../../widgets/academy_relink_dialog.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
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
            Icon(Icons.co_present_rounded, color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text('Teacher Portal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: [
          _notificationBell(context, user),
          IconButton(
            icon: const Icon(Icons.security_rounded, color: AppColors.accent),
            onPressed: () => _showSecuritySettings(context),
          ),
          const ThemeToggle(), // NEW
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
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text('Welcome, ${user?.fullName ?? 'Teacher'}',
                    style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 4),
              Text('Your classroom overview',
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
                'View Announcements',
                'View broadcasts from your academy',
                Icons.campaign_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ViewAnnouncementsScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Manage My Announcements',
                'Reach out to parents & students',
                Icons.add_comment_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TeacherAnnouncementsScreen()),
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
                'Grading & AI Paper Grader',
                'Enter marks or use AI to grade papers',
                Icons.add_chart_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const TeacherQuizListScreen(isAiGen: false)),
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
                  MaterialPageRoute(
                      builder: (_) =>
                          const TeacherQuizListScreen(isAiGen: true)),
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
                  MaterialPageRoute(
                      builder: (_) => const MonthlyReportScreen()),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Security Settings",
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
                "Enhance your account security with biometric authentication.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            StatefulBuilder(
              builder: (context, setInternalState) {
                final session = context.watch<SessionProvider>();
                return SwitchListTile(
                  title: const Text("Biometric / Face Unlock",
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  subtitle: const Text("Use fingerprints or face ID to log in.",
                      style: TextStyle(fontSize: 12)),
                  value: session.biometricEnabled,
                  activeThumbColor: AppColors.accent,
                  onChanged: (val) async {
                    if (val) {
                      final authenticated =
                          await session.authenticateWithBiometrics();
                      if (!context.mounted) return;
                      if (authenticated) {
                        final pass = await _promptForPassword(context);
                        if (pass != null) {
                          await session.setBiometricEnabled(true,
                              password: pass);
                        }
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.accent)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => showAcademyRelinkDialog(context),
              icon: const Icon(Icons.sync_problem_rounded),
              label: const Text("Fix Academy Link"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: AppColors.border),
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
            const Text("Enter a new password for your account.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            LabeledField(
                label: "New Password",
                hint: "Min 6 chars",
                controller: passCtrl,
                obscure: true),
            LabeledField(
                label: "Confirm Password",
                hint: "Re-enter",
                controller: confirmCtrl,
                obscure: true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              if (passCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Passwords do not match!")));
                return;
              }
              if (passCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Minimum 6 characters required!")));
                return;
              }
              try {
                await AuthService().directUpdatePassword(passCtrl.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Password updated successfully!")));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("UPDATE",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptForPassword(BuildContext context) async {
    final ctrl = TextEditingController();
    String? error;
    bool verifying = false;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.appColors.surface,
          title: const Text("Verify Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "Enter your account password to enable biometric login.",
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              LabeledField(
                  label: "Current Password",
                  hint: "Required",
                  controller: ctrl,
                  obscure: true),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12)),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("CANCEL")),
            TextButton(
              onPressed: verifying
                  ? null
                  : () async {
                      setDialogState(() {
                        verifying = true;
                        error = null;
                      });
                      final ok = await AuthService().verifyPassword(ctrl.text);
                      if (!ok) {
                        setDialogState(() {
                          verifying = false;
                          error = "Incorrect password.";
                        });
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx, ctrl.text);
                    },
              child: Text(verifying ? "VERIFYING..." : "VERIFY",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationBell(BuildContext context, dynamic user) {
    if (user == null) return const SizedBox();
    return StreamBuilder<List<dynamic>>(
      stream:
          NotificationService().watchForUser(user.uid, user.academyId ?? ''),
      builder: (context, snap) {
        final count =
            snap.hasData ? snap.data!.where((n) => !n.isRead).length : 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded,
                  color: AppColors.accent),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen())),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.danger, shape: BoxShape.circle),
                  child: Text('$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        );
      },
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
              border: Border.all(
                  color: context.appColors.border.withValues(alpha: 0.5)),
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
                              color: context.appColors.textMuted,
                              fontSize: 12)),
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
