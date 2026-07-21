import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../data/models/announcement.dart';
import '../../data/remote/announcement_service.dart';
import '../../logic/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';

class TeacherAnnouncementsScreen extends StatefulWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  State<TeacherAnnouncementsScreen> createState() =>
      _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState
    extends State<TeacherAnnouncementsScreen> {
  final _service = AnnouncementService();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final academyId = user?.academyId ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Announcements',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: academyId.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textOnAccent,
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text('New Announcement'),
              onPressed: () => _openComposeSheet(academyId),
            ),
      body: GradientBackground(
        child: SafeArea(
          child: academyId.isEmpty
              ? const Center(child: Text("Invalid session"))
              : StreamBuilder<List<Announcement>>(
                  stream: _service.watchAll(academyId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent),
                      );
                    }

                    // Teachers only see announcements THEY created here
                    final list = (snap.data ?? const [])
                        .where((a) => a.createdByUid == user?.uid)
                        .toList();

                    if (list.isEmpty) return _emptyState();

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _announcementTile(list[i], academyId),
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
          Icon(Icons.campaign_outlined, size: 56, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('No announcements sent yet',
              style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Tap "New Announcement" to reach parents & students',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _announcementTile(Announcement a, String academyId) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a.title,
                    style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              _targetChip(a.targetLabel),
            ],
          ),
          const SizedBox(height: 6),
          Text(a.message,
              style: TextStyle(
                  color: context.appColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              // Added Day and Date as requested
              Expanded(
                child: Text(DateFormat('EEEE, d MMM yyyy').format(a.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
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
        title: const Text('Delete announcement?'),
        content: const Text(
            'This will remove the message for all students and parents.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _service.delete(a.id);
    }
  }

  void _openComposeSheet(String academyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _TeacherComposeSheet(service: _service, academyId: academyId),
    );
  }
}

class _TeacherComposeSheet extends StatefulWidget {
  final AnnouncementService service;
  final String academyId;
  const _TeacherComposeSheet({required this.service, required this.academyId});

  @override
  State<_TeacherComposeSheet> createState() => _TeacherComposeSheetState();
}

class _TeacherComposeSheetState extends State<_TeacherComposeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool _students = true;
  bool _parents = true;
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>().currentUser;
    if (auth == null) return;

    setState(() => _saving = true);
    try {
      await widget.service.create(
        title: _titleCtrl.text,
        message: _messageCtrl.text,
        targetRoles: [
          if (_students) 'student',
          if (_parents) 'parent',
          'teacher', // So teacher can see their own message in View screen
        ],
        createdByUid: auth.uid,
        createdByName: auth.fullName,
        academyId: widget.academyId,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Announcement sent successfully!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('New Announcement',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              LabeledField(
                  label: 'Title',
                  hint: 'e.g. Tomorrow\'s Class Timing',
                  controller: _titleCtrl),
              const Text('Message',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageCtrl,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'Enter your message...'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Message is required' : null,
              ),
              const SizedBox(height: 20),
              const Text('RECIPIENTS',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _targetToggle('Students', _students,
                      (v) => setState(() => _students = v)),
                  const SizedBox(width: 12),
                  _targetToggle(
                      'Parents', _parents, (v) => setState(() => _parents = v)),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                  label: 'BROADCAST',
                  icon: Icons.send_rounded,
                  loading: _saving,
                  onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetToggle(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      checkmarkColor: AppColors.accent,
      labelStyle: TextStyle(
          color: value ? AppColors.accent : AppColors.textSecondary,
          fontWeight: value ? FontWeight.bold : FontWeight.normal),
    );
  }
}
