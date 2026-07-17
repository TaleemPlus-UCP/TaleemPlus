import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/quiz_provider.dart';
import '../../../logic/class_provider.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/gradient_background.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/models/test_mark_model.dart';

class MarkEntryScreen extends StatefulWidget {
  final QuizModel quiz;
  const MarkEntryScreen({super.key, required this.quiz});

  @override
  State<MarkEntryScreen> createState() => _MarkEntryScreenState();
}

class _MarkEntryScreenState extends State<MarkEntryScreen> {
  // Map to store temporary marks: { studentId : marksObtained }
  final Map<String, TextEditingController> _markControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-initialize controllers for each student in the class
    final cls = context.read<ClassProvider>().classes.firstWhere((c) => c.id == widget.quiz.classId);
    for (var uid in cls.studentIds) {
      _markControllers[uid] = TextEditingController();
    }
    _loadExistingMarks();
  }

  Future<void> _loadExistingMarks() async {
    // Optional: Load existing marks if already uploaded
  }

  @override
  void dispose() {
    for (var ctrl in _markControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _saveMarks() async {
    setState(() => _isSaving = true);
    try {
      final cls = context.read<ClassProvider>().classes.firstWhere((c) => c.id == widget.quiz.classId);
      final List<TestMarkModel> marksList = [];

      _markControllers.forEach((uid, ctrl) {
        if (ctrl.text.trim().isNotEmpty) {
          final obtained = double.tryParse(ctrl.text.trim()) ?? 0;
          final percentage = (obtained / widget.quiz.totalMarks) * 100;
          
          marksList.add(TestMarkModel(
            id: "${widget.quiz.id}_$uid",
            quizId: widget.quiz.id,
            studentId: uid,
            studentName: cls.studentNames[uid] ?? "Unknown",
            classId: widget.quiz.classId,
            marksObtained: obtained,
            totalMarks: widget.quiz.totalMarks,
            percentage: percentage,
            gradeLetter: TestMarkModel.calculateGrade(percentage),
            updatedAt: DateTime.now(),
          ));
        }
      });

      if (marksList.isEmpty) {
        _showSnackBar("No marks entered!", isError: true);
        return;
      }

      await context.read<QuizProvider>().gradeBulk(marksList);
      _showSnackBar("Marks uploaded successfully!");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Failed to save marks: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.danger : AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cls = context.watch<ClassProvider>().classes.firstWhere((c) => c.id == widget.quiz.classId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Test Marks', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _quizInfoCard(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: cls.studentIds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final uid = cls.studentIds[i];
                    final name = cls.studentNames[uid] ?? "Student";
                    return _studentMarkTile(name, _markControllers[uid]!);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: PrimaryButton(
                  label: "UPLOAD ALL MARKS",
                  icon: Icons.upload_file_rounded,
                  loading: _isSaving,
                  onPressed: _saveMarks,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quizInfoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.quiz.title, style: const TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("Max Marks: ${widget.quiz.totalMarks}", style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _studentMarkTile(String name, TextEditingController ctrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withOpacity(0.1),
            child: Text(name[0], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "0.0",
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                fillColor: AppColors.inputFill,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
