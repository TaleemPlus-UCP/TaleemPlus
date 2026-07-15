import 'package:flutter/material.dart';
import '../../widgets/role_dashboard_scaffold.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardScaffold(
      title: 'Student Portal',
      icon: Icons.school_rounded,
      features: [
        "Today's Assignments & Bulletins",
        'Attempt Quizzes (offline)',
        'AI Notes Summarizer',
        'View Attendance & Results',
        'Fee Ledger',
      ],
    );
  }
}
