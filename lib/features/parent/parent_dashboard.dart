import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../logic/auth_provider.dart';
import '../../logic/parent_provider.dart';
import '../../logic/session_provider.dart'; // NEW
import '../../data/models/app_user.dart';
import '../../data/remote/auth_service.dart';
import '../../widgets/app_widgets.dart';
import '../../data/remote/notification_service.dart';
import '../shared/notifications_screen.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/theme_toggle_widget.dart';
import '../shared/view_announcements_screen.dart';
import 'screens/child_overview_screen.dart';
import 'screens/all_challans_screen.dart';
import 'screens/academy_contact_screen.dart'; // NEW
import '../../widgets/academy_relink_dialog.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
    }
  }

  void _openLinkChildSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _LinkChildSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final parentProv = context.watch<ParentProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.family_restroom_rounded,
                color: AppColors.accent, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text('Parent Portal',
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
          const ThemeToggle(),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => parentProv.syncWithUser(user),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text('Welcome, ${user?.fullName ?? 'Parent'}',
                      style: TextStyle(
                          color: context.appColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 4),
                Text('Monitor your child\'s education journey',
                    style: TextStyle(color: context.appColors.textSecondary)),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('MY CHILDREN',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    TextButton.icon(
                      onPressed: () => _openLinkChildSheet(context),
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          size: 16),
                      label: const Text("ADD CHILD",
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (parentProv.loading && parentProv.children.isEmpty)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: AppColors.accent)))
                else if (parentProv.children.isEmpty)
                  _noChildrenPlaceholder(context)
                else
                  ...parentProv.children.map((c) => _childCard(context, c)),
                const SizedBox(height: 32),
                const Text('SERVICES',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _actionTile(
                  context,
                  'Fee Challans',
                  'Download and pay monthly invoices',
                  Icons.receipt_long_rounded,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AllChallansScreen())),
                ),
                const SizedBox(height: 12),
                _actionTile(
                  context,
                  'Announcements',
                  'General broadcasts and notices',
                  Icons.campaign_rounded,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ViewAnnouncementsScreen())),
                ),
                const SizedBox(height: 12),
                _actionTile(
                  context,
                  'Academy Support',
                  'Contact management and helpdesk',
                  Icons.support_agent_rounded,
                  () {
                    if (parentProv.children.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Please link a child first.")));
                      return;
                    }
                    final firstChild = parentProv.children.first;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AcademyContactScreen(
                                academyId: firstChild.academyId ?? '')));
                  },
                ),
              ],
            ),
          ),
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

  Widget _childCard(BuildContext context, AppUser child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withValues(alpha: 0.1),
          child: Text(
              child.fullName.isNotEmpty
                  ? child.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.bold)),
        ),
        title: Text(child.fullName,
            style: TextStyle(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.bold)),
        subtitle: Text(child.email,
            style: TextStyle(color: context.appColors.textMuted, fontSize: 12)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'remove') {
              _confirmUnlink(context, child);
            } else if (val == 'view') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChildOverviewScreen(child: child)));
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
                value: 'view',
                child: Row(children: [
                  Icon(Icons.visibility_rounded, size: 18),
                  SizedBox(width: 12),
                  Text("View Details")
                ])),
            const PopupMenuItem(
                value: 'remove',
                child: Row(children: [
                  Icon(Icons.link_off_rounded,
                      color: AppColors.danger, size: 18),
                  SizedBox(width: 12),
                  Text("Remove Child",
                      style: TextStyle(color: AppColors.danger))
                ])),
          ],
        ),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChildOverviewScreen(child: child))),
      ),
    );
  }

  void _confirmUnlink(BuildContext context, AppUser child) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: const Text("Remove Child?"),
        content: Text(
            "Are you sure you want to unlink ${child.fullName} from your dashboard?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              try {
                await context.read<ParentProvider>().unlinkChild(child.uid);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Failed to remove child: $e"),
                      backgroundColor: AppColors.danger));
                }
              }
            },
            child: const Text("REMOVE",
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _noChildrenPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: context.appColors.border.withValues(alpha: 0.3),
            style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.child_care_rounded,
              size: 48,
              color: context.appColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text("No children linked yet",
              style: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Link your child's profile to track their performance.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
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
                    Text(subtitle,
                        style: TextStyle(
                            color: context.appColors.textMuted, fontSize: 12)),
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

class _LinkChildSheet extends StatefulWidget {
  const _LinkChildSheet();

  @override
  State<_LinkChildSheet> createState() => _LinkChildSheetState();
}

class _LinkChildSheetState extends State<_LinkChildSheet> {
  final _searchCtrl = TextEditingController();
  final _authService = AuthService();
  List<AppUser> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String q) async {
    final queryText = q.trim().toLowerCase();
    if (queryText.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final parent = context.read<AuthProvider>().currentUser;
    if (parent == null || parent.academyId == null) return;

    setState(() => _searching = true);
    try {
      final list =
          await _authService.searchStudentsByName(queryText, parent.academyId!);
      if (mounted) {
        setState(() {
          _results = list;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Link Your Child",
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text("Search by your child's full name or email address.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          TextField(
            controller: _searchCtrl,
            onChanged: _performSearch,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: "Enter Name or Email...",
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.accent),
              suffixIcon: _searching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.accent)))
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _results = []);
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (_results.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (ctx, i) {
                  final s = _results[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                      child: Text(
                          s.fullName.isNotEmpty
                              ? s.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.accent, fontSize: 12)),
                    ),
                    title: Text(s.fullName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "${s.email}${s.academyName != null ? ' • ${s.academyName}' : ''}",
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    trailing: const Icon(Icons.add_link_rounded,
                        color: AppColors.accent),
                    onTap: () async {
                      try {
                        await context.read<ParentProvider>().addChild(s);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Child linked successfully!"),
                                backgroundColor: AppColors.success));
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Failed to link: $e"),
                              backgroundColor: AppColors.danger));
                        }
                      }
                    },
                  );
                },
              ),
            )
          else if (_searchCtrl.text.isNotEmpty && !_searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.person_search_rounded,
                      color: AppColors.textMuted, size: 48),
                  SizedBox(height: 12),
                  Text("No students found.",
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("Make sure the name or email is correct.",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
