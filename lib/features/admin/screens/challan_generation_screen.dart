import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/remote/api_exception.dart';
import '../../../logic/class_provider.dart';
import '../../../data/repositories/fee_challan_repository.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/app_widgets.dart';

class ChallanGenerationScreen extends StatefulWidget {
  const ChallanGenerationScreen({super.key});

  @override
  State<ChallanGenerationScreen> createState() =>
      _ChallanGenerationScreenState();
}

class _ChallanGenerationScreenState extends State<ChallanGenerationScreen> {
  final _repo = FeeChallanRepository();
  String? _selectedClassId;
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  final _monthlyFeeCtrl = TextEditingController(text: "3000");
  final _admissionFeeCtrl = TextEditingController(text: "0");
  final _examFeeCtrl = TextEditingController(text: "0");
  final _fineCtrl = TextEditingController(text: "0");

  bool _isGenerating = false;

  @override
  void dispose() {
    _monthlyFeeCtrl.dispose();
    _admissionFeeCtrl.dispose();
    _examFeeCtrl.dispose();
    _fineCtrl.dispose();
    super.dispose();
  }

  /// Due date for a challan billed for [monthName]: the 10th of that month.
  /// Since there is no year selector, a month earlier than the current one
  /// is assumed to refer to that month next year (e.g. generating a
  /// "January" challan in November means January next year).
  DateTime _dueDateForMonth(String monthName) {
    final now = DateTime.now();
    final monthIndex = _months.indexOf(monthName) + 1;
    var year = now.year;
    if (monthIndex < now.month) {
      year += 1;
    }
    return DateTime(year, monthIndex, 10);
  }

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

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassProvider>().classes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Challans',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildClassSelector(classes),
              const SizedBox(height: 16),
              _buildMonthSelector(),
              const SizedBox(height: 24),
              const Text("FEE STRUCTURE",
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 16),
              LabeledField(
                  label: "Monthly Tuition Fee",
                  hint: "3000",
                  controller: _monthlyFeeCtrl,
                  keyboardType: TextInputType.number),
              LabeledField(
                  label: "Admission Fee (One-time)",
                  hint: "0",
                  controller: _admissionFeeCtrl,
                  keyboardType: TextInputType.number),
              LabeledField(
                  label: "Exam Fee",
                  hint: "0",
                  controller: _examFeeCtrl,
                  keyboardType: TextInputType.number),
              LabeledField(
                  label: "Fine / Arrears",
                  hint: "0",
                  controller: _fineCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              PrimaryButton(
                label: "GENERATE FOR ENTIRE CLASS",
                icon: Icons.auto_awesome_motion_rounded,
                loading: _isGenerating,
                onPressed: (_selectedClassId == null || _isGenerating)
                    ? null
                    : _confirmAndGenerate,
              ),
              const SizedBox(height: 12),
              const Text(
                  "Note: This will create pending challans for all students enrolled in the selected class.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector(List<dynamic> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SELECT CLASS",
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedClassId,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              hint: const Text("Pick a class"),
              items: classes
                  .map((c) => DropdownMenuItem(
                      value: c.id as String,
                      child: Text(c.displayLabel as String,
                          style:
                              const TextStyle(color: AppColors.textPrimary))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedClassId = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("BILLING MONTH",
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMonth,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              items: _months
                  .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m,
                          style:
                              const TextStyle(color: AppColors.textPrimary))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedMonth = v!),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndGenerate() async {
    final cp = context.read<ClassProvider>();
    final clsMatches =
        cp.classes.where((c) => c.id == _selectedClassId).toList();
    if (clsMatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selected class no longer exists.'),
          backgroundColor: AppColors.danger));
      return;
    }
    final cls = clsMatches.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Generate challans?'),
        content: Text(
            'This will create pending challans for every student enrolled in '
            '${cls.displayLabel} for $_selectedMonth. Students who already '
            'have a challan for this month will be skipped. This cannot be '
            'undone automatically.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Generate')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _generateChallans();
    }
  }

  Future<void> _generateChallans() async {
    setState(() => _isGenerating = true);

    try {
      final cp = context.read<ClassProvider>();
      final cls = cp.classes.firstWhere((c) => c.id == _selectedClassId);

      if (cls.studentIds.isEmpty) {
        throw Exception("No students are enrolled in this class.");
      }

      final dueDate = _dueDateForMonth(_selectedMonth);
      final result = await _repo.generateForSection(
        sectionId: cls.sectionId,
        billingYear: dueDate.year,
        billingMonth: _months.indexOf(_selectedMonth) + 1,
        monthlyFee: double.tryParse(_monthlyFeeCtrl.text) ?? 0,
        admissionFee: double.tryParse(_admissionFeeCtrl.text) ?? 0,
        examFee: double.tryParse(_examFeeCtrl.text) ?? 0,
        fine: double.tryParse(_fineCtrl.text) ?? 0,
        dueDate: dueDate,
      );

      if (mounted) {
        final generated = result['generatedCount'];
        final skipped = result['skippedCount'];
        final skippedNote = (skipped is int && skipped > 0)
            ? " ($skipped already had one, skipped)"
            : "";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Generated $generated challans for $_selectedMonth!$skippedNote"),
            backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppColors.danger));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Generation failed: $e"),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
