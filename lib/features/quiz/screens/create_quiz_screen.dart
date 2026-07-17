import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/quiz_provider.dart';
import '../../../logic/class_provider.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/gradient_background.dart';
import '../../../data/models/quiz_model.dart';

class CreateQuizScreen extends StatefulWidget {
  final String classId;
  final bool isAiGen;
  const CreateQuizScreen({super.key, required this.classId, this.isAiGen = false});

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
  DateTime _testDate = DateTime.now();

  final List<QuizQuestion> _questions = [];

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  void _addQuestion() {
    // ... same as before
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgBottom,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddQuestionSheet(onAdd: (q) => setState(() => _questions.add(q))),
    );
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one question!')));
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    final cls = context.read<ClassProvider>().classes.firstWhere((c) => c.id == widget.classId);

    final quiz = QuizModel(
      id: const Uuid().v4(),
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

    await context.read<QuizProvider>().createQuiz(quiz);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test created successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAiGen ? 'AI Test Generator' : 'Create Test', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                _buildFormSection('TEST BASICS', [
                  LabeledField(label: 'Test Title', hint: 'e.g. Unit 1 Quiz', controller: _titleCtrl),
                  LabeledField(label: 'Subject', hint: 'e.g. Physics', controller: _subjectCtrl),
                ]),
                
                _buildFormSection('ACADEMY DETAILS', [
                  _buildDropdownField('Month', _selectedMonth, _months, (v) => setState(() => _selectedMonth = v!)),
                  const SizedBox(height: 16),
                  LabeledField(label: 'Test Session', hint: 'e.g. Annual 2024', controller: _sessionCtrl),
                  LabeledField(label: 'Chapter / Topic', hint: 'e.g. Kinematics', controller: _chapterCtrl),
                ]),

                _buildFormSection('SPECIFICATIONS', [
                  _buildDropdownField('Difficulty', _difficulty, ['Easy', 'Medium', 'Hard'], (v) => setState(() => _difficulty = v!)),
                  const SizedBox(height: 16),
                  LabeledField(label: 'Total Marks', hint: 'e.g. 20', controller: _totalMarksCtrl, keyboardType: TextInputType.number),
                  LabeledField(label: 'Instructions', hint: 'e.g. No calculators', controller: _instructionsCtrl),
                ]),
                
                const SizedBox(height: 10),
                const Text('QUESTIONS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 12),
                
                ..._questions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final q = entry.value;
                  return _questionCard(i + 1, q);
                }),

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                  label: const Text('Add Question', style: TextStyle(color: AppColors.accent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Save & Publish Test',
                  icon: Icons.cloud_upload_rounded,
                  loading: context.watch<QuizProvider>().loading,
                  onPressed: _saveQuiz,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
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
              items: items.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
              onChanged: onChanged,
              dropdownColor: AppColors.surface,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
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
                child: Text('$index', style: const TextStyle(color: AppColors.textOnAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Text(q.type == QuestionType.mcq ? 'MCQ' : 'Short Answer', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${q.marks} Marks', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                onPressed: () => setState(() => _questions.remove(q)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(q.text, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
  QuestionType _type = QuestionType.mcq;
  
  final List<TextEditingController> _optionCtrls = List.generate(4, (_) => TextEditingController());
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
            const Text('Add Question', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(
              children: [
                _typeBtn('MCQ', QuestionType.mcq),
                const SizedBox(width: 12),
                _typeBtn('Short Answer', QuestionType.short),
              ],
            ),
            const SizedBox(height: 20),
            LabeledField(label: 'Question Text', hint: 'Enter question', controller: _questionCtrl),
            LabeledField(label: 'Marks', hint: '1', controller: _marksCtrl, keyboardType: TextInputType.number),
            
            if (_type == QuestionType.mcq) ...[
              const Text('OPTIONS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._optionCtrls.asMap().entries.map((entry) {
                final i = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: _correctIdx,
                        onChanged: (v) => setState(() => _correctIdx = v!),
                        activeColor: AppColors.accent,
                      ),
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(hintText: 'Option ${i+1}', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add Question',
              onPressed: () {
                if (_questionCtrl.text.isEmpty) return;
                final q = QuizQuestion(
                  id: const Uuid().v4(),
                  text: _questionCtrl.text.trim(),
                  type: _type,
                  marks: double.tryParse(_marksCtrl.text) ?? 1,
                  options: _type == QuestionType.mcq ? _optionCtrls.map((c) => c.text).toList() : null,
                  correctIndex: _type == QuestionType.mcq ? _correctIdx : null,
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
            color: selected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border),
          ),
          child: Text(label, style: TextStyle(color: selected ? AppColors.accent : AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
