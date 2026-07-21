import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../logic/auth_provider.dart';
import '../../logic/fee_provider.dart';
import '../../logic/member_provider.dart';
import '../../logic/admin_ai_provider.dart';
import '../../widgets/gradient_background.dart';
import 'fee_ledger_screen.dart';
import 'admin_quiz_list_screen.dart';

class AdminAiPredictionScreen extends StatefulWidget {
  const AdminAiPredictionScreen({super.key});

  @override
  State<AdminAiPredictionScreen> createState() =>
      _AdminAiPredictionScreenState();
}

class _AdminAiPredictionScreenState extends State<AdminAiPredictionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        context.read<MemberProvider>().load(user.uid);
        context.read<FeeProvider>().load(user.uid);
        context.read<AdminAiProvider>().runAcademyAnalysis(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights & Predictions',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Consumer<AdminAiProvider>(
            builder: (context, ai, _) {
              if (ai.loading) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _aiStatusHeader(),
                  const SizedBox(height: 24),
                  _buildRiskPrediction(ai),
                  const SizedBox(height: 20),
                  _buildRevenueForecast(),
                  const SizedBox(height: 20),
                  _buildAcademicInsights(ai),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _aiStatusHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "OFFLINE INTELLIGENCE ACTIVE",
              style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1),
            ),
          ),
          Icon(Icons.bolt_rounded, color: AppColors.success, size: 16),
        ],
      ),
    );
  }

  Widget _buildRiskPrediction(AdminAiProvider ai) {
    final bool hasRisk = ai.atRiskCount > 0;
    return _predictionCard(
      title: "Student Success Risk",
      prediction: hasRisk
          ? "${ai.atRiskCount} Students at Risk"
          : "All Students Performing Well",
      insight: hasRisk
          ? "The following students need attention: ${ai.atRiskStudentNames.join(', ')}."
          : "Average academy performance is at ${ai.academyAvgPerformance.toStringAsFixed(1)}%. No major risks detected.",
      icon: Icons.person_search_rounded,
      color: hasRisk ? AppColors.warning : AppColors.success,
      actionLabel: "VIEW DETAILS",
      onAction: () => _showAtRiskDialog(context, ai),
    );
  }

  void _showAtRiskDialog(BuildContext context, AdminAiProvider ai) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("At-Risk Students",
            style: TextStyle(color: AppColors.textPrimary)),
        content: ai.atRiskCount > 0
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: ai.atRiskStudentNames
                    .map((name) => ListTile(
                          leading: const Icon(Icons.person,
                              color: AppColors.warning),
                          title: Text(name,
                              style: const TextStyle(
                                  color: AppColors.textPrimary)),
                        ))
                    .toList(),
              )
            : const Text("All students are performing above the 50% threshold.",
                style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  Widget _buildRevenueForecast() {
    return Consumer<FeeProvider>(
      builder: (context, feeProvider, _) {
        final double pending = feeProvider.totalPending;
        final double predicted =
            pending * 0.85; // Heuristic: 85% usually pay on time

        return _predictionCard(
          title: "Revenue Forecast",
          prediction: "Predicted Rs. ${predicted.toStringAsFixed(0)}",
          insight:
              "Expected collection for this month based on Rs. ${pending.toStringAsFixed(0)} total pending fees.",
          icon: Icons.payments_rounded,
          color: AppColors.success,
          actionLabel: "LEDGER",
          onAction: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FeeLedgerScreen())),
        );
      },
    );
  }

  Widget _buildAcademicInsights(AdminAiProvider ai) {
    return _predictionCard(
      title: "Subject Strength Analysis",
      prediction: "Weakest Area: ${ai.weakestSubject}",
      insight:
          "Academy-wide average marks in ${ai.weakestSubject} are currently the lowest across all subjects.",
      icon: Icons.analytics_rounded,
      color: AppColors.accent,
      actionLabel: "REPORTS",
      onAction: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AdminQuizListScreen())),
    );
  }

  Widget _predictionCard({
    required String title,
    required String prediction,
    required String insight,
    required IconData icon,
    required Color color,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(prediction,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(insight,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAction,
              child: Text(actionLabel,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
