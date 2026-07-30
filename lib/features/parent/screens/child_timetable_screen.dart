import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/app_user.dart';
import '../../../logic/timetable_provider.dart';
import '../../shared/timetable_view.dart';

class ChildTimetableScreen extends StatelessWidget {
  final AppUser child;
  const ChildTimetableScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TimetableView(
      title: "${child.fullName}'s Timetable",
      emptyMessage:
          'No timetable has been published for this child\'s classes yet.',
      stream: context.read<TimetableProvider>().watchForStudent(child.uid),
    );
  }
}
