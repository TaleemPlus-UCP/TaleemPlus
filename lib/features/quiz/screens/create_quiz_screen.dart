import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/quiz_provider.dart';
import '../../../logic/class_provider.dart';
import '../../../logic/session_provider.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/gradient_background.dart';
import '../../../data/models/quiz_model.dart';

class CreateQuizScreen extends StatefulWidget {
  final String classId;
  final bool isAiGen;
  const CreateQuizScreen(
      {super.key, required this.classId, this.isAiGen = false});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _totalMarksCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _chapterCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController(text: 'Monthly Test');

  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  String _difficulty = 'Medium';
  final DateTime _testDate = DateTime.now();

  final List<QuizQuestion> _questions = [];

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  bool _isAnalyzing = false;

  Future<void> _pickImageAndAnalyze() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading:
                const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
            title: const Text("Camera",
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.image_rounded, color: AppColors.accent),
            title: const Text("Gallery",
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;
    if (!mounted) return;

    final session = context.read<SessionProvider>();
    session.suppressBackgroundLogout();
    final XFile? pickedFile;
    try {
      pickedFile = await picker.pickImage(source: source);
    } finally {
      session.resumeBackgroundLogoutTracking();
    }
    if (pickedFile == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final inputImage = InputImage.fromFile(File(pickedFile.path));
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (recognizedText.text.trim().isEmpty) {
        throw Exception("No text detected in the image!");
      }

      _analyzeContentAndShowRecommendations(recognizedText.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("AI Analysis Failed: $e"),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _analyzeContentAndShowRecommendations(String text) {
    // Offline AI Heuristic Logic
    final lines = text.split('\n').where((l) => l.trim().length > 10).toList();
    final wordCount = text.split(' ').length;

    // 1. Difficulty prediction based on average word length and complex markers
    String predictedDifficulty = "Medium";
    if (wordCount < 100) predictedDifficulty = "Easy";
    if (text.contains('law') ||
        text.contains('theorem') ||
        text.contains('equation') ||
        wordCount > 500) {
      predictedDifficulty = "Hard";
    }

    // 2. Question counts based on content density
    int mcqs = (wordCount / 40).clamp(3, 15).toInt();
    int sqs = (lines.length / 4).clamp(2, 10).toInt();
    int lqs = (wordCount > 300) ? 2 : 1;

    _showAiRecommendationsDialog(predictedDifficulty, mcqs, sqs, lqs,
        text.substring(0, text.length > 100 ? 100 : text.length));
  }

  void _showAiRecommendationsDialog(
      String diff, int mcqs, int sqs, int lqs, String preview) {
    final mcqCountCtrl = TextEditingController(text: mcqs.toString());
    final sqCountCtrl = TextEditingController(text: sqs.toString());
    final lqCountCtrl = TextEditingController(text: lqs.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
            SizedBox(width: 10),
            Text("AI Test Blueprint",
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Topic: $preview...",
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              _aiStatRow("Predicted Difficulty", diff, AppColors.accent),
              const Divider(color: AppColors.border, height: 24),
              const Text("ADJUST QUESTION COUNTS:",
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              _countInput("MCQs", mcqCountCtrl),
              _countInput("Short Questions", sqCountCtrl),
              _countInput("Long Questions", lqCountCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL",
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textOnAccent),
            onPressed: () {
              final mCount = int.tryParse(mcqCountCtrl.text) ?? mcqs;
              final sCount = int.tryParse(sqCountCtrl.text) ?? sqs;
              final lCount = int.tryParse(lqCountCtrl.text) ?? lqs;

              _generateQuestionsLocally(preview, diff, mCount, sCount, lCount);

              setState(() {
                _difficulty = diff;
                _instructionsCtrl.text =
                    "Attempt all $mCount MCQs, $sCount Short Questions and $lCount Long Questions.";
              });
              Navigator.pop(ctx);
            },
            child: const Text("GENERATE & APPLY"),
          ),
        ],
      ),
    );
  }

  Widget _countInput(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13))),
          SizedBox(
            width: 60,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                fillColor: AppColors.inputFill,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateQuestionsLocally(
      String extractedText, String diff, int mcqs, int sqs, int lqs) {
    // 100% Offline Heuristic Question Generation.
    // ML Kit OCR breaks text on visual line boundaries, not sentence
    // boundaries, so a raw '\n' split rarely produces a long enough line to
    // trigger the "long question" heuristic and often chops "X is Y"
    // definitions mid-sentence, starving the MCQ heuristic too. Rejoining
    // into one blob and re-splitting on sentence terminators gives each
    // heuristic real sentence-level text to work with.
    final normalized = extractedText.replaceAll(RegExp(r'\s+'), ' ').trim();
    final sentences = normalized
        .split(RegExp(r'[.?!]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 15)
        .toList();

    final List<QuizQuestion> generated = [];
    final usedSentences = <String>{};

    // Heuristic 1: MCQs from "X is/refers to Y" definitions.
    int mGenerated = 0;
    for (var sentence in sentences) {
      if (mGenerated >= mcqs) break;
      if (usedSentences.contains(sentence)) continue;
      if (sentence.contains(' is ') || sentence.contains(' refers to ')) {
        final parts = sentence.split(RegExp(r' is | refers to '));
        if (parts.length == 2 &&
            parts[0].trim().isNotEmpty &&
            parts[1].trim().isNotEmpty) {
          generated.add(QuizQuestion(
            id: const Uuid().v4(),
            text:
                "What ${sentence.contains(' refers to ') ? 'refers to' : 'is'} ${parts[1].trim()}?",
            type: QuestionType.mcq,
            options: [
              parts[0].trim(),
              "None of the above",
              "Both A and B",
              "Incorrect definition"
            ],
            correctIndex: 0,
            marks: 1.0,
          ));
          usedSentences.add(sentence);
          mGenerated++;
        }
      }
    }

    // Remaining sentences, longest first, so the longest ones become Long
    // Questions and the rest are available for Short Questions.
    final remaining = sentences.where((s) => !usedSentences.contains(s))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    // Heuristic 2: Long Questions from the longest remaining sentences.
    int lGenerated = 0;
    for (var sentence in remaining) {
      if (lGenerated >= lqs) break;
      if (usedSentences.contains(sentence)) continue;
      if (sentence.length < 80) continue;
      final preview =
          sentence.length > 60 ? '${sentence.substring(0, 60)}...' : sentence;
      generated.add(QuizQuestion(
        id: const Uuid().v4(),
        text: "Discuss in detail the following concept: $preview",
        type: QuestionType.long,
        marks: 5.0,
      ));
      usedSentences.add(sentence);
      lGenerated++;
    }

    // Heuristic 3: Short Questions from whatever's left.
    int sGenerated = 0;
    for (var sentence in remaining) {
      if (sGenerated >= sqs) break;
      if (usedSentences.contains(sentence)) continue;
      if (sentence.contains('?')) continue;
      generated.add(QuizQuestion(
        id: const Uuid().v4(),
        text: "Briefly explain: $sentence",
        type: QuestionType.short,
        marks: 2.0,
      ));
      usedSentences.add(sentence);
      sGenerated++;
    }

    setState(() {
      _questions.addAll(generated);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Generated ${generated.length} questions from notes!"),
          backgroundColor: AppColors.success),
    );
  }

  Widget _aiStatRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13))),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  color: valColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _addQuestion() {
    // ... same as before
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _AddQuestionSheet(onAdd: (q) => setState(() => _questions.add(q))),
    );
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one question!')));
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cp = Provider.of<ClassProvider>(context, listen: false);

    final user = auth.currentUser;
    final cls = cp.classes.firstWhere((c) => c.id == widget.classId);

    final quiz = QuizModel(
      id: const Uuid().v4(),
      academyId: user?.academyId ?? '',
      classId: widget.classId,
      classLabel: "${cls.className} (${cls.section})",
      title: _titleCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      month: _selectedMonth,
      session: _sessionCtrl.text.trim(),
      chapter: _chapterCtrl.text.trim(),
      difficulty: _difficulty,
      totalMarks: double.tryParse(_totalMarksCtrl.text) ?? 0,
      testDate: _testDate,
      instructions: _instructionsCtrl.text.trim(),
      createdByUid: user!.uid,
      createdByName: user.fullName,
      createdAt: DateTime.now(),
      questions: _questions,
    );

    try {
      await context.read<QuizProvider>().createQuiz(quiz);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test created successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to create test: $e'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAiGen ? 'AI Test Generator' : 'Create Test',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.isAiGen) ...[
                  _buildAiScanButton(),
                  const SizedBox(height: 24),
                ],
                _buildFormSection('TEST BASICS', [
                  LabeledField(
                      label: 'Test Title',
                      hint: 'e.g. Unit 1 Quiz',
                      controller: _titleCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null),
                  LabeledField(
                      label: 'Subject',
                      hint: 'e.g. Physics',
                      controller: _subjectCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Subject is required'
                          : null),
                ]),
                _buildFormSection('ACADEMY DETAILS', [
                  _buildDropdownField('Month', _selectedMonth, _months,
                      (v) => setState(() => _selectedMonth = v!)),
                  const SizedBox(height: 16),
                  LabeledField(
                      label: 'Test Session',
                      hint: 'e.g. Annual 2024',
                      controller: _sessionCtrl),
                  LabeledField(
                      label: 'Chapter / Topic',
                      hint: 'e.g. Kinematics',
                      controller: _chapterCtrl),
                ]),
                _buildFormSection('SPECIFICATIONS', [
                  _buildDropdownField(
                      'Difficulty',
                      _difficulty,
                      ['Easy', 'Medium', 'Hard'],
                      (v) => setState(() => _difficulty = v!)),
                  const SizedBox(height: 16),
                  LabeledField(
                      label: 'Total Marks',
                      hint: 'e.g. 20',
                      controller: _totalMarksCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final marks = double.tryParse(v?.trim() ?? '');
                        if (marks == null || marks <= 0) {
                          return 'Enter total marks greater than 0';
                        }
                        return null;
                      }),
                  LabeledField(
                      label: 'Instructions',
                      hint: 'e.g. No calculators',
                      controller: _instructionsCtrl),
                ]),
                const SizedBox(height: 10),
                const Text('QUESTIONS',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                ..._questions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final q = entry.value;
                  return _questionCard(i + 1, q);
                }),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.accent),
                  label: const Text('Add Question',
                      style: TextStyle(color: AppColors.accent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Save & Publish Test',
                  icon: Icons.cloud_upload_rounded,
                  loading: context.watch<QuizProvider>().loading,
                  onPressed:
                      context.watch<QuizProvider>().loading ? null : _saveQuiz,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiScanButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              SizedBox(width: 10),
              Text("AI TEST ASSISTANT",
                  style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
              "Take a photo of the textbook topic to get suggested question counts and difficulty.",
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: "SCAN TOPIC WITH AI",
            icon: Icons.camera_enhance_rounded,
            loading: _isAnalyzing,
            onPressed: _pickImageAndAnalyze,
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items
                  .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m,
                          style:
                              const TextStyle(color: AppColors.textPrimary))))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: AppColors.surface,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _questionCard(int index, QuizQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.accent,
                child: Text('$index',
                    style: const TextStyle(
                        color: AppColors.textOnAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Text(
                  switch (q.type) {
                    QuestionType.mcq => 'MCQ',
                    QuestionType.long => 'Long Answer',
                    QuestionType.short => 'Short Answer',
                  },
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${q.marks} Marks',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 18),
                onPressed: () => setState(() => _questions.remove(q)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(q.text,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AddQuestionSheet extends StatefulWidget {
  final Function(QuizQuestion) onAdd;
  const _AddQuestionSheet({required this.onAdd});

  @override
  State<_AddQuestionSheet> createState() => _AddQuestionSheetState();
}

class _AddQuestionSheetState extends State<_AddQuestionSheet> {
  final _questionCtrl = TextEditingController();
  final _marksCtrl = TextEditingController(text: '1');
  final _keywordsCtrl = TextEditingController();
  QuestionType _type = QuestionType.mcq;

  final List<TextEditingController> _optionCtrls =
      List.generate(4, (_) => TextEditingController());
  int _correctIdx = 0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Question',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(
              children: [
                _typeBtn('MCQ', QuestionType.mcq),
                const SizedBox(width: 12),
                _typeBtn('Short Answer', QuestionType.short),
                const SizedBox(width: 12),
                _typeBtn('Long Answer', QuestionType.long),
              ],
            ),
            const SizedBox(height: 20),
            LabeledField(
                label: 'Question Text',
                hint: 'Enter question',
                controller: _questionCtrl),
            LabeledField(
                label: 'Marks',
                hint: '1',
                controller: _marksCtrl,
                keyboardType: TextInputType.number),
            if (_type == QuestionType.short || _type == QuestionType.long)
              LabeledField(
                label: 'Grading Keywords (Optional)',
                hint: 'e.g. Force, mass, acceleration (comma separated)',
                controller: _keywordsCtrl,
              ),
            if (_type == QuestionType.mcq) ...[
              const Text('OPTIONS',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              RadioGroup<int>(
                groupValue: _correctIdx,
                onChanged: (v) => setState(() => _correctIdx = v!),
                child: Column(
                  children: _optionCtrls.asMap().entries.map((entry) {
                    final i = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<int>(
                        value: i,
                        activeColor: AppColors.accent,
                        contentPadding: EdgeInsets.zero,
                        title: TextField(
                          controller: entry.value,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Option ${i + 1}',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add Question',
              onPressed: () {
                if (_questionCtrl.text.isEmpty) return;

                final keywords = _keywordsCtrl.text
                    .split(',')
                    .map((e) => e.trim().toLowerCase())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final q = QuizQuestion(
                  id: const Uuid().v4(),
                  text: _questionCtrl.text.trim(),
                  type: _type,
                  marks: double.tryParse(_marksCtrl.text) ?? 1,
                  options: _type == QuestionType.mcq
                      ? _optionCtrls.map((c) => c.text).toList()
                      : null,
                  correctIndex: _type == QuestionType.mcq ? _correctIdx : null,
                  gradingKeywords: keywords,
                );
                widget.onAdd(q);
                Navigator.pop(context);
              },
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String label, QuestionType t) {
    final selected = _type == t;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = t),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
