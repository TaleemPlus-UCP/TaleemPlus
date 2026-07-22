import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/quiz_provider.dart';
import '../../../widgets/gradient_background.dart';
import '../../../data/models/test_mark_model.dart';

class StudentTestReportScreen extends StatelessWidget {
  final String studentUid;
  final String studentName;

  const StudentTestReportScreen({
    super.key,
    required this.studentUid,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final academyId = user?.academyId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text("$studentName's Report",
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: academyId.isEmpty
              ? const Center(child: Text("Academy session error"))
              : StreamBuilder<List<TestMarkModel>>(
                  stream: context
                      .read<QuizProvider>()
                      .watchStudentResults(studentUid, academyId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent));
                    }

                    final results = snapshot.data ?? [];

                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.analytics_outlined,
                                size: 64,
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text(
                              "No test records found for this student.",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        _buildSummaryHeader(results),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _resultTile(results[index]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(List<TestMarkModel> results) {
    final double avgPercentage =
        results.map((r) => r.percentage).reduce((a, b) => a + b) /
            results.length;
    final String overallGrade = TestMarkModel.calculateGrade(avgPercentage);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.2),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("OVERALL PROGRESS",
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Text("${avgPercentage.toStringAsFixed(1)}%",
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900)),
              const Text("Average Percentage",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                const Text("GRADE",
                    style: TextStyle(
                        color: AppColors.textOnAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
                Text(overallGrade,
                    style: const TextStyle(
                        color: AppColors.textOnAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultTile(TestMarkModel res) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getGradeColor(res.gradeLetter).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              res.gradeLetter,
              style: TextStyle(
                color: _getGradeColor(res.gradeLetter),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res.subject,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(res.updatedAt),
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${res.marksObtained.toStringAsAlpha(0)} / ${res.totalMarks.toStringAsAlpha(0)}",
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
              Text(
                "${res.percentage.toStringAsFixed(0)}%",
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return AppColors.success;
      case 'B':
      case 'C':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }
}

extension on double {
  String toStringAsAlpha(int fractionDigits) {
    if (this == truncateToDouble()) return truncate().toString();
    return toStringAsFixed(fractionDigits);
  }
}
