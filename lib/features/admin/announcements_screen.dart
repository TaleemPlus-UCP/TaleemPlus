import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/announcement.dart';
import '../../data/remote/announcement_service.dart';
import '../../logic/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _service = AnnouncementService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Announcements',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.campaign_rounded),
        label: const Text('New Announcement'),
        onPressed: _openComposeSheet,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: StreamBuilder<List<Announcement>>(
            stream: _service.watchAll(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              if (snap.hasError) {
                return const Center(
                  child: Text('Could not load announcements.',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              final list = snap.data ?? const [];
              if (list.isEmpty) return _emptyState();
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _announcementTile(list[i]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined,
              size: 56, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('No announcements yet',
              style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Tap "New Announcement" to broadcast one',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _announcementTile(Announcement a) {
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
              Expanded(
                child: Text(a.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              _targetChip(a.targetLabel),
            ],
          ),
          const SizedBox(height: 6),
          Text(a.message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(a.createdByName,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(width: 12),
              const Icon(Icons.schedule_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(DateFormat('d MMM yyyy, h:mm a').format(a.createdAt),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
              const Spacer(),
              IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.textSecondary),
                onPressed: () => _openComposeSheet(existing: a),
              ),
              const SizedBox(width: 8),
              IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger),
                onPressed: () => _confirmDelete(a),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _targetChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }

  Future<void> _confirmDelete(Announcement a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        title: const Text('Delete announcement?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Remove "${a.title}" for everyone?',
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
      await _service.delete(a.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted')),
        );
      }
    }
  }

  void _openComposeSheet({Announcement? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ComposeSheet(
        existing: existing,
        service: _service,
      ),
    );
  }
}

/// Bottom sheet to create OR edit an announcement.
class _ComposeSheet extends StatefulWidget {
  final Announcement? existing;
  final AnnouncementService service;
  const _ComposeSheet({this.existing, required this.service});

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _messageCtrl;

  bool _sendToAll = true;
  bool _teachers = false;
  bool _students = false;
  bool _parents = false;

  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _messageCtrl = TextEditingController(text: e?.message ?? '');
    if (e != null) {
      if (e.isForAll) {
        _sendToAll = true;
      } else {
        _sendToAll = false;
        _teachers = e.targetRoles.contains('teacher');
        _students = e.targetRoles.contains('student');
        _parents = e.targetRoles.contains('parent');
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  List<String> _resolveTargets() {
    if (_sendToAll) return ['all'];
    return [
      if (_teachers) 'teacher',
      if (_students) 'student',
      if (_parents) 'parent',
    ];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final targets = _resolveTargets();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick at least one audience')),
      );
      return;
    }

    final auth = context.read<AuthProvider>().currentUser;
    if (auth == null) return;

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await widget.service.update(
          id: widget.existing!.id,
          title: _titleCtrl.text,
          message: _messageCtrl.text,
          targetRoles: targets,
        );
      } else {
        await widget.service.create(
          title: _titleCtrl.text,
          message: _messageCtrl.text,
          targetRoles: targets,
          createdByUid: auth.uid,
          createdByName: auth.fullName,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditing
                  ? 'Announcement updated'
                  : 'Announcement broadcast')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not save. Check your connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
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
              Text(_isEditing ? 'Edit Announcement' : 'New Announcement',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 20),
              LabeledField(
                label: 'Title',
                hint: 'e.g. Mock Exams Schedule',
                controller: _titleCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const Text('Message',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageCtrl,
                minLines: 3,
                maxLines: 6,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Write your message here...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Message is required'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('AUDIENCE',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  )),
              const SizedBox(height: 8),
              _audienceRow(
                label: 'Everyone',
                icon: Icons.groups_rounded,
                selected: _sendToAll,
                onTap: () => setState(() {
                  _sendToAll = true;
                  _teachers = _students = _parents = false;
                }),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _pickChip(
                      label: 'Teachers',
                      selected: !_sendToAll && _teachers,
                      onTap: () => setState(() {
                        _sendToAll = false;
                        _teachers = !_teachers;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _pickChip(
                      label: 'Students',
                      selected: !_sendToAll && _students,
                      onTap: () => setState(() {
                        _sendToAll = false;
                        _students = !_students;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _pickChip(
                      label: 'Parents',
                      selected: !_sendToAll && _parents,
                      onTap: () => setState(() {
                        _sendToAll = false;
                        _parents = !_parents;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Broadcast',
                icon: Icons.send_rounded,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _audienceRow({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.accent : AppColors.textMuted,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _pickChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? AppColors.accent : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
      ),
    );
  }
}