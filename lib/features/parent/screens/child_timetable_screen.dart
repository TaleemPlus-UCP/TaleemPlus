import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/app_user.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/class_provider.dart';
import '../../../logic/timetable_provider.dart';
import '../../../widgets/web/web_nav_items.dart';
import '../../shared/timetable_view.dart';

class ChildTimetableScreen extends StatefulWidget {
  final AppUser child;
  const ChildTimetableScreen({super.key, required this.child});

  @override
  State<ChildTimetableScreen> createState() => _ChildTimetableScreenState();
}

class _ChildTimetableScreenState extends State<ChildTimetableScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ClassProvider>().listenAll(user.academyId ?? '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final academyId = user?.academyId ?? '';
    final childClassIds = context
        .watch<ClassProvider>()
        .classes
        .where((c) => c.studentIds.contains(widget.child.uid))
        .map((c) => c.id)
        .toList();

    return TimetableView(
      title: "${widget.child.fullName}'s Timetable",
      emptyMessage:
          'No timetable has been published for this child\'s classes yet.',
      stream: context
          .read<TimetableProvider>()
          .watchForClassIds(childClassIds, academyId),
      webNavSections: buildParentNavSections(context,
          onDashboard: () => Navigator.of(context).popUntil((r) => r.isFirst)),
      webActiveNavId: 'dashboard',
      webUser: user,
    );
  }
}
