import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/class_entity.dart';
import '../../logic/auth_provider.dart';
import '../../logic/class_provider.dart';
import '../../widgets/gradient_background.dart';
import '../quiz/screens/teacher_quiz_list_screen.dart';
import 'screens/classroom_management_screen.dart';
import 'attendance_marking_screen.dart';

/// Streams the classes assigned to the logged-in teacher (matched by email
/// against `primary_teacher_email` on the class doc in Firestore).
class TeacherClassesScreen extends StatelessWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Classes',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: user == null
              ? const _EmptyMessage(text: 'Please log in again.')
              : StreamBuilder<List<ClassEntity>>(
            stream: context
                .read<ClassProvider>()
                .streamForTeacher(user.uid, user.academyId ?? ''),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accent),
                );
              }
              if (snap.hasError) {
                return const _EmptyMessage(
                    text: 'Could not load classes.');
              }
              final list = snap.data ?? const [];
              if (list.isEmpty) return _emptyState();
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _classTile(context, list[i]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.class_outlined,
                  size: 56, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('No classes assigned yet',
                  style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(height: 4),
              Text('Ask your admin to assign you a class',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _classTile(BuildContext context, ClassEntity c) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showOptions(context, c),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                child: const Icon(Icons.class_rounded,
                    color: AppColors.accent),
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
                    Text(
                        '${c.enrollmentCount} students · Tap to mark attendance',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
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

  void _showOptions(BuildContext context, ClassEntity c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.displayLabel,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.fact_check_rounded, color: AppColors.accent),
              title: const Text("Mark Attendance"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AttendanceMarkingScreen(classEntity: c)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology_rounded, color: AppColors.accent),
              title: const Text("AI Paper Grader"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TeacherQuizListScreen(
                              isAiGen: false,
                              initialClassId: c.id,
                            )));
              },
            ),
            ListTile(
              leading: const Icon(Icons.door_sliding_rounded,
                  color: AppColors.accent),
              title: const Text("Manage Classroom (Resources & Queries)"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ClassroomManagementScreen(classEntity: c)));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  const _EmptyMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text,
          style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
