import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';
import '../../data/remote/auth_service.dart';
import '../../logic/auth_provider.dart';
import '../../logic/member_provider.dart';
import '../../widgets/gradient_background.dart';

/// Admin screen: list users waiting for approval and approve/reject them.
class ApprovalRequestsScreen extends StatefulWidget {
  const ApprovalRequestsScreen({super.key});

  @override
  State<ApprovalRequestsScreen> createState() =>
      _ApprovalRequestsScreenState();
}

class _ApprovalRequestsScreenState extends State<ApprovalRequestsScreen> {
  final _authService = AuthService();
  List<AppUser> _pending = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _authService.getPendingUsers();
      if (!mounted) return;
      setState(() {
        _pending = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load requests. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _approve(AppUser u) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final admin = auth.currentUser;
    if (admin == null) return;

    // 1. Update status in Firebase to 'active' and tie to THIS admin's academy
    await _authService.approveUser(u.uid, admin.uid);

    // 2. Also mirror this user into the local User Management portal
    if (u.role != UserRole.admin) {
      if (!mounted) return;
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      final alreadyPresent =
      memberProvider.members.any((m) => m.id == u.uid);
      if (!alreadyPresent) {
        await memberProvider.addMember(
          fullName: u.fullName,
          email: u.email,
          phone: u.phoneNumber,
          role: u.role.value, 
          academyId: admin.uid, 
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${u.fullName} approved for your academy')),
      );
      // Refresh global counts
      Provider.of<MemberProvider>(context, listen: false).load(admin.uid);
      _load();
    }
  }

  Future<void> _reject(AppUser u) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final admin = auth.currentUser;
    if (admin == null) return;

    // Only change the status; keep the record for admin history.
    await _authService.rejectUser(u.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${u.fullName} rejected')),
      );
      // Refresh global counts for THIS academy
      Provider.of<MemberProvider>(context, listen: false).load(admin.uid);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Approval Requests',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _load,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(_error!,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      );
    }
    if (_pending.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          const Center(
            child: Column(
              children: [
                Icon(Icons.done_all_rounded,
                    size: 56, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('No pending requests',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _requestTile(_pending[i]),
    );
  }

  Widget _requestTile(AppUser u) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                child: Text(
                  u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.fullName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text(u.role.label,
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 12)),
                    Text(u.email,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  onPressed: () => _reject(u),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textOnAccent,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  onPressed: () => _approve(u),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
