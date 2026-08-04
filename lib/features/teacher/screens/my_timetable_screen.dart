import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/timetable_provider.dart';
import '../../../widgets/web/web_nav_items.dart';
import '../../shared/timetable_view.dart';

class MyTimetableScreen extends StatelessWidget {
  const MyTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return TimetableView(
      title: 'My Timetable',
      emptyMessage: 'No classes have been scheduled for you yet.',
      stream: context
          .read<TimetableProvider>()
          .watchForTeacher(user?.uid ?? '', user?.academyId ?? ''),
      webNavSections: buildTeacherNavSections(context,
          onDashboard: () => Navigator.of(context).popUntil((r) => r.isFirst)),
      webActiveNavId: 'my_timetable',
      webUser: user,
    );
  }
}
