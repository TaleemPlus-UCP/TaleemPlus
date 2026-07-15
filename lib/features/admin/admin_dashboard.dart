import 'package:flutter/material.dart';
import '../../widgets/role_dashboard_scaffold.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboardScaffold(
      title: 'Admin Portal',
      icon: Icons.admin_panel_settings_rounded,
      features: [
        'Manage Users (Teachers / Students / Parents)',
        'Fee Ledger & Defaulter Tracking',
        'Academy Financial Analytics',
        'Broadcast Announcements',
        'Predictive Analysis (at-risk students)',
      ],
    );
  }
}
