import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../logic/parent_provider.dart';
import '../../../widgets/gradient_background.dart';
import 'student_challan_screen.dart';

class AllChallansScreen extends StatelessWidget {
  const AllChallansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final children = context.watch<ParentProvider>().children;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Challans',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: children.isEmpty
              ? _buildNoChildrenState()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: children.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final child = children[i];
                    return _childChallanTile(context, child);
                  },
                ),
        ),
      ),
    );
  }

  Widget _childChallanTile(BuildContext context, dynamic child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                child: Text(
                  child.fullName.isNotEmpty
                      ? child.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.fullName,
                        style: TextStyle(
                            color: context.appColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Text("Student Profile",
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => StudentChallanScreen(studentUid: child.uid)),
            ),
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: const Text("VIEW CHALLAN"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textOnAccent,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChildrenState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.child_care_rounded,
                size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text("No children linked",
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold)),
            Text("Please link a child first to see their fee challans.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
