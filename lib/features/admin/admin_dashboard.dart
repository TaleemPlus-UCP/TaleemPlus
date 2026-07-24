import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';
import '../../data/remote/auth_service.dart';
import '../../logic/auth_provider.dart';
import '../../logic/member_provider.dart';
import '../../logic/session_provider.dart';
import '../../data/remote/notification_service.dart';
import '../../widgets/app_widgets.dart';
import '../shared/notifications_screen.dart'; // NEW
import '../../widgets/gradient_background.dart';
import '../../widgets/theme_toggle_widget.dart';
import '../../core/theme/theme_extensions.dart';
import 'user_management_screen.dart';
import 'approval_requests_screen.dart';
import 'fee_ledger_screen.dart';
import 'announcements_screen.dart';
import 'class_management_screen.dart';
import 'admin_quiz_list_screen.dart';
import 'admin_ai_prediction_screen.dart';
import 'screens/challan_generation_screen.dart';

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
      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final members = Provider.of<MemberProvider>(context, listen: false);
        final user = auth.currentUser;
        if (user != null) {
          members.load(user.uid);
          _verifyLegacyAdminData(user);
        }
      }
    });
  }

  /// Ensures old admins get an Academy Code and ID if they don't have one.
  /// Best-effort: a failure here shouldn't surface as an unhandled Future
  /// rejection since this runs unawaited from initState — it'll simply be
  /// retried the next time the dashboard loads.
  Future<void> _verifyLegacyAdminData(AppUser user) async {
    if (user.academyCode == null || user.academyId == null) {
      try {
        final newCode = "TP-${user.uid.substring(0, 5).toUpperCase()}";
        await AuthService().updateAcademyProfile(
          uid: user.uid,
          name: user.academyName ?? "My Academy",
          address: user.academyAddress ?? "N/A",
          phone: user.academyPhone ?? user.phoneNumber,
        );
        // Update firestore directly for the missing fields
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'academy_code': newCode,
          'academy_id': user.uid,
          'joining_date': user.createdAt ?? FieldValue.serverTimestamp(),
        });
        if (mounted) {
          // Refresh local user state
          context.read<AuthProvider>().tryRestoreSession();
        }
      } catch (e) {
        debugPrint('Legacy admin data migration failed: $e');
      }
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
    }
  }

  void _showSecuritySettings(BuildContext context) {
    // ... logic remains same
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: const Text("Change Password"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter a new password for your account.",
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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

  void _showAcademyInfoSettings(BuildContext context, AppUser? user) {
    if (user == null) return;

    final nameCtrl =
        TextEditingController(text: user.academyName ?? "SRS Tech Matrix");
    final addressCtrl = TextEditingController(
        text: user.academyAddress ?? "123 Education Lane, Lahore");
    final phoneCtrl =
        TextEditingController(text: user.academyPhone ?? "03014334151");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Academy Information",
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                "Update details for official reports and parents support section.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                backgroundImage: user.academyLogo != null
                    ? NetworkImage(user.academyLogo!)
                    : null,
                child: user.academyLogo == null
                    ? const Icon(Icons.business_rounded,
                        color: AppColors.accent, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            LabeledField(
                label: "Academy Name",
                hint: "SRS Tech Matrix",
                controller: nameCtrl),
            LabeledField(
                label: "Address",
                hint: "Enter full address",
                controller: addressCtrl),
            LabeledField(
                label: "Contact Number",
                hint: "+92...",
                controller: phoneCtrl,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            PrimaryButton(
              label: "SAVE CHANGES",
              onPressed: () async {
                await AuthService().updateAcademyProfile(
                  uid: user.uid,
                  name: nameCtrl.text,
                  address: addressCtrl.text,
                  phone: phoneCtrl.text,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Info updated successfully!")));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final members = context.watch<MemberProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded,
                color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text('Admin Portal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: [
          _notificationBell(context, user),
          IconButton(
            icon: const Icon(Icons.business_rounded, color: AppColors.accent),
            tooltip: 'Academy Info',
            onPressed: () => _showAcademyInfoSettings(context, user),
          ),
          IconButton(
            icon: const Icon(Icons.security_rounded, color: AppColors.accent),
            onPressed: () => _showSecuritySettings(context),
          ),
          const ThemeToggle(),
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
            onRefresh: () async {
              if (user != null) {
                await members.load(user.uid);
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Welcome, ${user?.fullName ?? 'Admin'}',
                    style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                if (user?.academyName != null) ...[
                  const SizedBox(height: 4),
                  Text(user!.academyName!,
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 4),
                Text('Academy overview',
                    style: TextStyle(color: context.appColors.textSecondary)),
                const SizedBox(height: 16),

                // NEW: Display Academy Code for easy sharing
                if (user?.academyCode != null)
                  _buildAcademyCodeCard(user!.academyCode!),

                const SizedBox(height: 20),
                Row(
                  children: [
                    _statCard(
                      'Teachers',
                      members.totalTeachers,
                      Icons.co_present_rounded,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const UserManagementScreen(initialIndex: 0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      'Students',
                      members.totalStudents,
                      Icons.school_rounded,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const UserManagementScreen(initialIndex: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      'Parents',
                      members.totalParents,
                      Icons.family_restroom_rounded,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const UserManagementScreen(initialIndex: 2),
                        ),
                      ),
                    ),
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
                    MaterialPageRoute(builder: (_) => const FeeLedgerScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _actionTile(
                  'Bulk Fee Challans',
                  'Generate monthly invoices for classes',
                  Icons.request_quote_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChallanGenerationScreen()),
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
                const SizedBox(height: 12),
                _actionTile(
                  'Test Reports & Grading',
                  'Monitor student performance and results',
                  Icons.analytics_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminQuizListScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _actionTile(
                  'AI Prediction & Insights',
                  'Predict student risk and revenue trends',
                  Icons.auto_awesome_rounded,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminAiPredictionScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notificationBell(BuildContext context, AppUser? user) {
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

  Widget _statCard(String label, int value, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              color: context.appColors.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: context.appColors.border.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.accent, size: 24),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('$value',
                      style: TextStyle(
                          color: context.appColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcademyCodeCard(String code) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ACADEMY JOINING CODE",
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                Text(code,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_rounded,
                color: AppColors.accent, size: 20),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Academy Code copied to clipboard!")));
              }
            },
          ),
        ],
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
