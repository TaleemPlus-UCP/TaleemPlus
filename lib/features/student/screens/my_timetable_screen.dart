import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/class_provider.dart';
import '../../../logic/timetable_provider.dart';
import '../../shared/timetable_view.dart';

class MyTimetableScreen extends StatefulWidget {
  const MyTimetableScreen({super.key});

  @override
  State<MyTimetableScreen> createState() => _MyTimetableScreenState();
}

class _MyTimetableScreenState extends State<MyTimetableScreen> {
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
    // Each subject a student takes is a separate `classId` in this app's
    // data model (see ClassEntity) — same pattern MyClassroomHub uses to
    // find "my classes".
    final myClassIds = context
        .watch<ClassProvider>()
        .classes
        .where((c) => c.studentIds.contains(user?.uid))
        .map((c) => c.id)
        .toList();

    return TimetableView(
      title: 'My Timetable',
      emptyMessage: 'No timetable has been published for your classes yet.',
      stream: context
          .read<TimetableProvider>()
          .watchForClassIds(myClassIds, academyId),
    );
  }
}
