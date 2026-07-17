import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/academy_member.dart';
import '../../logic/member_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _roles = const ['teacher', 'student', 'parent'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _currentRole => _roles[_tabController.index];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('User Management',
            style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Teachers'),
            Tab(text: 'Students'),
            Tab(text: 'Parents'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('Add ${_labelFor(_currentRole)}'),
        onPressed: () => _openAddSheet(_currentRole),
      ),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: TabBarView(
            controller: _tabController,
            children: _roles.map(_buildRoleList).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleList(String role) {
    return Consumer<MemberProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        final list = provider.byRole(role);
        if (list.isEmpty) {
          return _emptyState(role);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _memberTile(list[i]),
        );
      },
    );
  }

  Widget _emptyState(String role) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_off_rounded,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No ${_labelFor(role).toLowerCase()}s added yet',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add ${_labelFor(role)}" to create one',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(AcademyMember m) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: Text(
              m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.fullName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 2),
                if (m.extra.isNotEmpty)
                  Text(m.extra,
                      style: const TextStyle(
                          color: AppColors.accent, fontSize: 12)),
                if (m.email.isNotEmpty)
                  Text(m.email,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                if (m.phone.isNotEmpty)
                  Text(m.phone,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(m),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AcademyMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        title: const Text('Delete member?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Remove ${m.fullName} permanently?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<MemberProvider>().removeMember(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${m.fullName} removed')),
        );
      }
    }
  }

  void _openAddSheet(String role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMemberSheet(role: role),
    );
  }

  String _labelFor(String role) {
    switch (role) {
      case 'teacher':
        return 'Teacher';
      case 'student':
        return 'Student';
      case 'parent':
        return 'Parent';
      default:
        return 'Member';
    }
  }
}

class _AddMemberSheet extends StatefulWidget {
  final String role;
  const _AddMemberSheet({required this.role});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<MemberProvider>().addMember(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      role: widget.role,
      extra: _extraCtrl.text,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_nameCtrl.text} added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final label = AcademyMember.extraLabelFor(widget.role);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add ${widget.role[0].toUpperCase()}${widget.role.substring(1)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: 'Full Name',
                hint: 'Enter full name',
                controller: _nameCtrl,
                validator: Validators.fullName,
              ),
              LabeledField(
                label: label,
                hint: 'Enter $label',
                controller: _extraCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? '$label is required'
                    : null,
              ),
              LabeledField(
                label: 'Email (optional)',
                hint: 'name@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              LabeledField(
                label: 'Phone',
                hint: '+92 300 1234567',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: Validators.phone,
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Save',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}