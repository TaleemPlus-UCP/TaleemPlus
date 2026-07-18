import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/academy_member.dart';
import '../../data/remote/auth_service.dart';
import '../../logic/auth_provider.dart';
import '../../logic/member_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../core/theme/theme_extensions.dart';

class UserManagementScreen extends StatefulWidget {
  final int initialIndex;
  const UserManagementScreen({super.key, this.initialIndex = 0});

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
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        context.read<MemberProvider>().load(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (ctx, _) {
          final role = _roles[_tabController.index];
          return FloatingActionButton.extended(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textOnAccent,
            icon: const Icon(Icons.person_add_alt_1),
            label: Text('Add ${_labelFor(role)}'),
            onPressed: () => _openAddSheet(ctx, role),
          );
        },
      ),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: TabBarView(
            controller: _tabController,
            children: _roles.map((r) => _RoleListTab(role: r)).toList(),
          ),
        ),
      ),
    );
  }

  void _openAddSheet(BuildContext ctx, String role) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
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

class _RoleListTab extends StatefulWidget {
  final String role;
  const _RoleListTab({required this.role});

  @override
  State<_RoleListTab> createState() => _RoleListTabState();
}

class _RoleListTabState extends State<_RoleListTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<MemberProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        
        var list = provider.byRole(widget.role);
        if (_query.isNotEmpty) {
          list = list.where((m) => 
            m.fullName.toLowerCase().contains(_query.toLowerCase()) || 
            m.extra.toLowerCase().contains(_query.toLowerCase()) ||
            m.phone.contains(_query)
          ).toList();
        }

        return Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: list.isEmpty 
                ? _emptyState(widget.role)
                : RepaintBoundary(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _memberTile(ctx, list[i]),
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        style: TextStyle(color: context.appColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search by name or ${_labelForSearch(widget.role)}...",
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          fillColor: context.appColors.surface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  String _labelForSearch(String role) {
    switch (role) {
      case 'teacher': return 'designation';
      case 'student': return 'roll number';
      case 'parent': return 'child name';
      default: return 'details';
    }
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
            'No ${role}s added yet',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Add" to create one',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(BuildContext context, AcademyMember m) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
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
                    style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 2),
                if (m.extra.isNotEmpty)
                  Text(m.extra,
                      style: const TextStyle(
                          color: AppColors.accent, fontSize: 12)),
                if (m.email.isNotEmpty)
                  Text(m.email,
                      style: TextStyle(
                          color: context.appColors.textSecondary, fontSize: 12)),
                if (m.phone.isNotEmpty)
                  Text(m.phone,
                      style: TextStyle(
                          color: context.appColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, m),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, AcademyMember m) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        title: const Text('Delete member?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Remove ${m.fullName} permanently?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        await ctx.read<MemberProvider>().removeMember(m.id, user.uid);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('${m.fullName} removed')),
          );
        }
      }
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
  final _passwordCtrl = TextEditingController(text: "123456"); // Default password
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _extraCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final auth = AuthService();
      final admin = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (admin == null) return;

      // 1. Create account in Firebase directly as 'active' and tie to current admin academy
      await auth.adminCreateUser(
        fullName: _nameCtrl.text,
        email: _emailCtrl.text,
        phoneNumber: _phoneCtrl.text,
        password: _passwordCtrl.text,
        role: UserRole.values.firstWhere((r) => r.name == widget.role),
        academyId: admin.uid, // PASS ACADEMY ID
        extraInfo: _extraCtrl.text,
      );

      // 2. Refresh counts in Provider
      if (mounted) {
        await context.read<MemberProvider>().load(admin.uid);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_nameCtrl.text} added with active portal')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add user: $e'), backgroundColor: AppColors.danger),
        );
      }
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
                'Create ${widget.role[0].toUpperCase()}${widget.role.substring(1)} Account',
                style: TextStyle(
                  color: context.appColors.textPrimary,
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
                label: 'Email Address',
                hint: 'name@taleem.edu.pk',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              LabeledField(
                label: 'Login Password',
                hint: 'Min 6 characters',
                controller: _passwordCtrl,
                validator: Validators.password,
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
                label: 'Phone',
                hint: '+92 300 1234567',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: Validators.phone,
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Create Account',
                icon: Icons.person_add_rounded,
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
