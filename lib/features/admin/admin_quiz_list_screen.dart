import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/quiz_provider.dart';
import '../../../logic/class_provider.dart';
import '../../../widgets/gradient_background.dart';
import '../../../data/models/quiz_model.dart';
import '../quiz/screens/quiz_results_screen.dart';

class AdminQuizListScreen extends StatefulWidget {
  const AdminQuizListScreen({super.key});

  @override
  State<AdminQuizListScreen> createState() => _AdminQuizListScreenState();
}

class _AdminQuizListScreenState extends State<AdminQuizListScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final academyId =
          Provider.of<AuthProvider>(context, listen: false).currentUser?.uid ??
              '';
      context.read<ClassProvider>().listenAll(academyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassProvider>().classes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Reports & Grading',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FILTER BY CLASS',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedClassId,
                          hint: const Text('All Classes',
                              style: TextStyle(color: AppColors.textSecondary)),
                          dropdownColor: AppColors.surface,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.accent),
                          items: classes.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text("${c.className} (${c.section})",
                                  style: const TextStyle(
                                      color: AppColors.textPrimary)),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedClassId = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _selectedClassId == null
                    ? _buildAllQuizzes()
                    : _buildQuizList(_selectedClassId!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllQuizzes() {
    return const Center(
      child: Text('Select a class to view test reports',
          style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  Widget _buildQuizList(String classId) {
    final academyId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.uid ??
            '';
    return StreamBuilder<List<QuizModel>>(
      stream:
          context.read<QuizProvider>().watchTeacherQuizzes(classId, academyId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(
              child: Text('No tests found for this class',
                  style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _quizTile(list[i]),
        );
      },
    );
  }

  Widget _quizTile(QuizModel quiz) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuizResultsScreen(quiz: quiz)),
        ),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: AppColors.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    Text("${quiz.subject} • ${quiz.totalMarks} Marks",
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
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
