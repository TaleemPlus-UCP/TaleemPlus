import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/quiz_provider.dart';
import '../../../logic/class_provider.dart';
import '../../../widgets/gradient_background.dart';
import '../../../data/models/test_mark_model.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  String? _selectedClassId;
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassProvider>().classes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Performance', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildFilters(classes),
              Expanded(
                child: _selectedClassId == null
                    ? _buildEmptyState('Select a class to view reports')
                    : _buildReportList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(List<dynamic> classes) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _dropdownContainer(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedClassId,
                  hint: const Text('Class', style: TextStyle(color: AppColors.textSecondary)),
                  items: classes.map((c) => DropdownMenuItem(value: c.id as String, child: Text(c.displayLabel as String, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
                  onChanged: (v) => setState(() => _selectedClassId = v),
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dropdownContainer(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMonth,
                  items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m.substring(0, 3), style: const TextStyle(color: AppColors.textPrimary)))).toList(),
                  onChanged: (v) => setState(() => _selectedMonth = v!),
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildReportList() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: context.read<QuizProvider>().watchMonthlyClassReport(_selectedClassId!, _selectedMonth),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        final data = snap.data;
        if (data == null || (data['studentStats'] as Map).isEmpty) {
          return _buildEmptyState('No data found for $_selectedMonth');
        }

        final stats = data['studentStats'] as Map<String, dynamic>;
        final students = stats.values.toList();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: students.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _studentReportCard(students[i]),
        );
      },
    );
  }

  Widget _studentReportCard(dynamic s) {
    final double obtained = s['obtained'];
    final double total = s['total'];
    final double percentage = (obtained / total) * 100;
    final grade = TestMarkModel.calculateGrade(percentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                child: Text(s['name'][0], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name'], style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Overall: $obtained / $total", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(grade, style: TextStyle(color: _getGradeColor(grade), fontSize: 18, fontWeight: FontWeight.w900)),
                  Text("${percentage.toStringAsFixed(1)}%", style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          ... (s['subjects'] as Map<String, dynamic>).entries.map((sub) {
            final subObtained = sub.value['obtained'];
            final subTotal = sub.value['total'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sub.key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text("$subObtained / $subTotal", style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getGradeColor(String g) {
    if (g.startsWith('A')) return AppColors.success;
    if (g.startsWith('B')) return AppColors.accent;
    if (g == 'F') return AppColors.danger;
    return AppColors.warning;
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
