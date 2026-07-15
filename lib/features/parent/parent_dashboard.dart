import 'package:flutter/material.dart';
import '../../widgets/role_dashboard_scaffold.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardScaffold(
      title: 'Parent Portal',
      icon: Icons.family_restroom_rounded,
      features: [
        'Attendance Tracking (per child)',
        'Tuition Fee Statement & History',
        'AI Early-Warning Alerts',
        'Absence Alerts & Acknowledgement',
        'Messages from Academy',
      ],
    );
  }
}
