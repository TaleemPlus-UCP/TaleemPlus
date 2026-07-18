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
import '../../widgets/app_widgets.dart'; // NEW
import '../../widgets/gradient_background.dart';
import '../../widgets/theme_toggle_widget.dart';
import '../shared/view_announcements_screen.dart';
import 'screens/child_overview_screen.dart';
import 'screens/all_challans_screen.dart';
import 'screens/academy_contact_screen.dart'; // NEW

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.login, (r) => false);
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
            Icon(Icons.family_restroom_rounded, color: AppColors.accent, size: 22),
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
              Text('Welcome, ${user?.fullName ?? 'Parent'}',
                  style: TextStyle(color: context.appColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Monitor your child\'s education journey', style: TextStyle(color: context.appColors.textSecondary)),
              const SizedBox(height: 28),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MY CHILDREN',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  TextButton.icon(
                    onPressed: () => _openLinkChildSheet(context),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                    label: const Text("ADD CHILD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (parentProv.children.isEmpty)
                _noChildrenPlaceholder(context)
              else
                ...parentProv.children.map((c) => _childCard(context, c)),

              const SizedBox(height: 32),
              const Text('SERVICES',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Fee Challans',
                'Download and pay monthly invoices',
                Icons.receipt_long_rounded,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllChallansScreen())),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Announcements',
                'General broadcasts and notices',
                Icons.campaign_rounded,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAnnouncementsScreen())),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                'Academy Support',
                'Contact management and helpdesk',
                Icons.support_agent_rounded,
                () {
                   if (parentProv.children.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please link a child first.")));
                     return;
                   }
                   // Pass the academyId of the first child as a default
                   final firstChild = parentProv.children.first;
                   Navigator.push(context, MaterialPageRoute(builder: (_) => AcademyContactScreen(academyId: firstChild.academyId ?? '')));
                },
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
                  activeThumbColor: AppColors.accent,
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

  Widget _childCard(BuildContext context, AppUser child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withValues(alpha: 0.1),
          child: Text(child.fullName[0].toUpperCase(), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
        ),
        title: Text(child.fullName, style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.bold)),
        subtitle: Text(child.email, style: TextStyle(color: context.appColors.textMuted, fontSize: 12)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'remove') {
              _confirmUnlink(context, child);
            } else if (val == 'view') {
               Navigator.push(context, MaterialPageRoute(builder: (_) => ChildOverviewScreen(child: child)));
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility_rounded, size: 18), SizedBox(width: 12), Text("View Details")])),
            const PopupMenuItem(value: 'remove', child: Row(children: [Icon(Icons.link_off_rounded, color: AppColors.danger, size: 18), SizedBox(width: 12), Text("Remove Child", style: TextStyle(color: AppColors.danger))])),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildOverviewScreen(child: child))),
      ),
    );
  }

  void _confirmUnlink(BuildContext context, AppUser child) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: const Text("Remove Child?"),
        content: Text("Are you sure you want to unlink ${child.fullName} from your dashboard?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await context.read<ParentProvider>().unlinkChild(child.uid);
              if (context.mounted) Navigator.pop(ctx);
            }, 
            child: const Text("REMOVE", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
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
        border: Border.all(color: context.appColors.border.withValues(alpha: 0.3), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.child_care_rounded, size: 48, color: context.appColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text("No children linked yet", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Link your child's profile to track their performance.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
    if (q.trim().length < 3) {
      setState(() => _results = []);
      return;
    }

    setState(() => _searching = true);
    try {
      final list = await _authService.searchStudentsByName(q);
      if (mounted) {
        setState(() {
          _results = list;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _searching = false);
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
          const Text("Search by your child's full name to link their profile.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          TextField(
            controller: _searchCtrl,
            onChanged: _performSearch,
            decoration: InputDecoration(
              hintText: "Enter child's name...",
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent),
              suffixIcon: _searching 
                  ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          if (_results.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (ctx, i) {
                  final s = _results[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                      child: Text(s.fullName[0].toUpperCase(), style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                    ),
                    title: Text(s.fullName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(s.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    trailing: const Icon(Icons.add_link_rounded, color: AppColors.accent),
                    onTap: () async {
                      await context.read<ParentProvider>().addChild(s);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Child linked successfully!")));
                    },
                  );
                },
              ),
            )
          else if (_searchCtrl.text.length >= 3 && !_searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("No students found with that name.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
