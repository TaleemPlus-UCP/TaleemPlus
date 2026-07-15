import 'package:flutter/material.dart';
import '../../widgets/role_dashboard_scaffold.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardScaffold(
      title: 'Teacher Portal',
      icon: Icons.co_present_rounded,
      features: [
        'Mark Attendance (offline-first)',
        'OCR Document Scanner (ML Kit)',
        'AI Test Paper Generator',
        'Notes Summarizer',
        'View Performance Predictions',
      ],
    );
  }
}
