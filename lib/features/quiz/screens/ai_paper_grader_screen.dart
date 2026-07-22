import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/models/test_mark_model.dart';
import '../../../data/models/class_entity.dart';
import '../../../logic/quiz_provider.dart';
import '../../../logic/class_provider.dart';
import '../../../logic/session_provider.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/app_widgets.dart';

class AiPaperGraderScreen extends StatefulWidget {
  final QuizModel quiz;
  const AiPaperGraderScreen({super.key, required this.quiz});

  @override
  State<AiPaperGraderScreen> createState() => _AiPaperGraderScreenState();
}

class _AiPaperGraderScreenState extends State<AiPaperGraderScreen> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  bool _isProcessing = false;

  // Grading state
  final Map<String, double> _suggestedMarks = {}; // questionId: suggestedScore
  final Map<String, String> _extractedText = {}; // questionId: text

  @override
  Widget build(BuildContext context) {
    final classProv = context.watch<ClassProvider>();
    final clsList =
        classProv.classes.where((c) => c.id == widget.quiz.classId).toList();

    if (clsList.isEmpty) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text("Class data not found.")));
    }
    final cls = clsList.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Smart Grader',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildStudentSelector(cls),
              Expanded(
                child: _selectedStudentId == null
                    ? _buildNoStudentState()
                    : _buildQuestionList(),
              ),
              if (_selectedStudentId != null) _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSelector(ClassEntity cls) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SELECT STUDENT TO GRADE",
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStudentId,
                isExpanded: true,
                dropdownColor: context.appColors.surfaceAlt,
                hint: const Text("Choose a student"),
                items: cls.studentIds.map((sid) {
                  final name = cls.studentNames[sid] ?? 'Student';
                  return DropdownMenuItem(value: sid, child: Text(name));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedStudentId = val;
                    _selectedStudentName = cls.studentNames[val];
                    _suggestedMarks.clear();
                    _extractedText.clear();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    final shortQuestions = widget.quiz.questions
        .where((q) => q.type == QuestionType.short)
        .toList();

    if (shortQuestions.isEmpty) {
      return const Center(
          child: Text("Only 'Short Answer' questions support AI grading."));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: shortQuestions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _gradingCard(shortQuestions[index]),
    );
  }

  Widget _gradingCard(QuizQuestion q) {
    final hasResult = _suggestedMarks.containsKey(q.id);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: hasResult
                ? AppColors.success.withValues(alpha: 0.3)
                : context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(q.text,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              const SizedBox(width: 10),
              Text("${q.marks} Pts",
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text("Keywords: ${q.gradingKeywords.join(', ')}",
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontStyle: FontStyle.italic)),
          const Divider(height: 32),
          if (hasResult) ...[
            _resultPreview(q),
            const SizedBox(height: 16),
          ],
          PrimaryButton(
            label: hasResult ? "RE-SCAN PAPER" : "SCAN ANSWER SHEET",
            icon: Icons.camera_alt_rounded,
            loading: _isProcessing,
            onPressed: () => _pickAndGrade(q),
          ),
        ],
      ),
    );
  }

  Widget _resultPreview(QuizQuestion q) {
    final score = _suggestedMarks[q.id] ?? 0;
    final text = _extractedText[q.id] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DETECTED TEXT:",
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: context.appColors.inputFill,
              borderRadius: BorderRadius.circular(12)),
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("SUGGESTED SCORE:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text("${score.toStringAsFixed(1)} / ${q.marks}",
                  style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAndGrade(QuizQuestion q) async {
    final picker = ImagePicker();
    final session = context.read<SessionProvider>();
    session.suppressBackgroundLogout();
    final XFile? img;
    try {
      img = await picker.pickImage(source: ImageSource.camera);
    } finally {
      session.resumeBackgroundLogoutTracking();
    }
    if (img == null) return;

    setState(() => _isProcessing = true);

    try {
      // 1. OCR (100% Offline via ML Kit)
      final inputImage = InputImage.fromFile(File(img.path));
      final recognizer = TextRecognizer();
      final result = await recognizer.processImage(inputImage);
      final rawText = result.text.toLowerCase();
      await recognizer.close();

      if (rawText.trim().isEmpty) throw Exception("No text detected!");

      // 2. Local AI Logic (Keyword Matching)
      int matches = 0;
      for (var kw in q.gradingKeywords) {
        if (rawText.contains(kw.toLowerCase())) matches++;
      }

      // 3. Heuristic Scoring
      double suggested = 0;
      if (q.gradingKeywords.isNotEmpty) {
        double matchRatio = matches / q.gradingKeywords.length;
        suggested = q.marks * matchRatio;
      }

      setState(() {
        _suggestedMarks[q.id] = suggested;
        _extractedText[q.id] = rawText;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: PrimaryButton(
        label: "APPROVE & SAVE MARKS",
        icon: Icons.check_circle_rounded,
        loading: _isProcessing,
        onPressed:
            (_suggestedMarks.isEmpty || _isProcessing) ? null : _saveTotalMarks,
      ),
    );
  }

  Future<void> _saveTotalMarks() async {
    if (_selectedStudentId == null) return;

    setState(() => _isProcessing = true);

    try {
      // Calculate total
      double obtained = 0;
      _suggestedMarks.forEach((_, score) => obtained += score);

      final mark = TestMarkModel(
        id: "${widget.quiz.id}_$_selectedStudentId",
        academyId: widget.quiz.academyId,
        quizId: widget.quiz.id,
        studentId: _selectedStudentId!,
        studentName: _selectedStudentName!,
        classId: widget.quiz.classId,
        subject: widget.quiz.subject,
        month: widget.quiz.month,
        marksObtained: obtained,
        totalMarks: widget.quiz.totalMarks,
        percentage: (obtained / widget.quiz.totalMarks) * 100,
        gradeLetter: TestMarkModel.calculateGrade(
            (obtained / widget.quiz.totalMarks) * 100),
        updatedAt: DateTime.now(),
      );

      await context.read<QuizProvider>().uploadBulkMarks([mark]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Paper graded and saved!"),
            backgroundColor: AppColors.success));
        setState(() {
          _selectedStudentId = null;
          _suggestedMarks.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Firebase Error: $e"),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildNoStudentState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded,
              size: 64,
              color: context.appColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text("Select a student to begin AI grading",
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
