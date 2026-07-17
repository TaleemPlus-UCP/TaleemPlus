import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/app_user.dart';
import '../../data/models/class_entity.dart';
import '../../data/remote/auth_service.dart';
import '../../logic/class_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().listenAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Class Management',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Class'),
        onPressed: _openAddSheet,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Consumer<ClassProvider>(
            builder: (context, cp, _) {
              if (cp.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              if (cp.classes.isEmpty) return _emptyState();
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: cp.classes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _classTile(cp.classes[i]),
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
          Icon(Icons.class_outlined, size: 56, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('No classes yet',
              style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Tap "New Class" to create one',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _classTile(ClassEntity c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.class_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.displayLabel,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 2),
                if (c.primaryTeacherName.isNotEmpty)
                  Text('Teacher: ${c.primaryTeacherName}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                Text(
                    '${c.enrollmentCount} student${c.enrollmentCount == 1 ? '' : 's'} enrolled',
                    style: const TextStyle(
                        color: AppColors.accent, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(c),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ClassEntity c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        title: const Text('Delete class?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
            'Remove ${c.displayLabel} and all its attendance records?',
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
      await context.read<ClassProvider>().deleteClass(c.id);
    }
  }

  Future<void> _openAddSheet() async {
    // Show loading, fetch approved teachers + students from Firebase
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    final auth = AuthService();
    List<AppUser> teachers = [];
    List<AppUser> students = [];
    try {
      teachers = await auth.getApprovedByRole(UserRole.teacher);
      students = await auth.getApprovedByRole(UserRole.student);
    } catch (_) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Could not load users. Check your connection.')),
        );
      }
      return;
    }
    if (mounted) Navigator.pop(context);

    if (!mounted) return;
    if (teachers.isEmpty || students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(teachers.isEmpty
              ? 'No approved teachers. Ask them to sign up and approve them.'
              : 'No approved students. Ask them to sign up and approve them.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddClassSheet(
        teachers: teachers,
        students: students,
      ),
    );
  }
}

class _AddClassSheet extends StatefulWidget {
  final List<AppUser> teachers;
  final List<AppUser> students;
  const _AddClassSheet({required this.teachers, required this.students});

  @override
  State<_AddClassSheet> createState() => _AddClassSheetState();
}

class _AddClassSheetState extends State<_AddClassSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  AppUser? _selectedTeacher;
  final Set<String> _selectedStudentUids = {};
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sectionCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a primary teacher')),
      );
      return;
    }
    final chosen = widget.students
        .where((s) => _selectedStudentUids.contains(s.uid))
        .toList();

    setState(() => _saving = true);
    try {
      await context.read<ClassProvider>().createClassWithStudents(
        className: _nameCtrl.text,
        section: _sectionCtrl.text,
        subject: _subjectCtrl.text,
        teacher: _selectedTeacher!,
        students: chosen,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Class "${_nameCtrl.text}" created with ${chosen.length} student(s)')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text('Could not create class. Check your connection.')),
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
              const Text('Create Class',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 20),
              LabeledField(
                label: 'Class Name',
                hint: 'e.g. Class 10, Grade 8',
                controller: _nameCtrl,
                validator: Validators.fullName,
              ),
              LabeledField(
                label: 'Section (optional)',
                hint: 'e.g. A, Blue, Morning',
                controller: _sectionCtrl,
              ),
              LabeledField(
                label: 'Subject (optional)',
                hint: 'e.g. Physics, Mathematics',
                controller: _subjectCtrl,
              ),
              const Text('PRIMARY TEACHER',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AppUser>(
                    value: _selectedTeacher,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceAlt,
                    hint: const Text('Select a teacher',
                        style: TextStyle(color: AppColors.textMuted)),
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: widget.teachers
                        .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.fullName),
                    ))
                        .toList(),
                    onChanged: (t) => setState(() => _selectedTeacher = t),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('STUDENTS',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const Spacer(),
                  Text('${_selectedStudentUids.length} selected',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              _studentPickerList(),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Create Class',
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

  Widget _studentPickerList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.students.length,
        itemBuilder: (_, i) {
          final s = widget.students[i];
          final selected = _selectedStudentUids.contains(s.uid);
          return InkWell(
            onTap: () => setState(() {
              if (selected) {
                _selectedStudentUids.remove(s.uid);
              } else {
                _selectedStudentUids.add(s.uid);
              }
            }),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: selected
                        ? AppColors.accent
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.fullName,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                        Text(s.email,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}