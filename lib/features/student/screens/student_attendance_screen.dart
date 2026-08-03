import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/attendance_provider.dart';
import '../../../logic/class_provider.dart';
import '../../../widgets/gradient_background.dart';
import '../../../data/models/attendance_record.dart';
import '../../../data/models/class_entity.dart';

class StudentAttendanceScreen extends StatelessWidget {
  final String studentUid;
  const StudentAttendanceScreen({super.key, required this.studentUid});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final academyId = user?.academyId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: academyId.isEmpty
              ? const Center(child: Text("Academy session error"))
              : StreamBuilder<List<ClassEntity>>(
                  stream: context
                      .read<ClassProvider>()
                      .streamForStudent(studentUid, academyId),
                  builder: (context, courseSnap) {
                    final courses = courseSnap.data ?? const [];
                    return StreamBuilder<List<AttendanceRecord>>(
                      stream: context
                          .read<AttendanceProvider>()
                          .watchStudentAttendance(studentUid, academyId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            courseSnap.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.accent));
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppColors.danger, size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Error loading records: ${snapshot.error}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.danger),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "If you see an 'index' error, please wait a minute for Firestore to auto-generate it or check your rules.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final records = snapshot.data ?? [];

                        if (records.isEmpty && courses.isEmpty) {
                          return _buildEmptyState();
                        }

                        return Column(
                          children: [
                            _buildStatsHeader(records),
                            Expanded(
                              child: _buildCourseGroupedView(courses, records),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(List<AttendanceRecord> records) {
    final total = records.length;
    final present = records.where((r) => r.status == 'present').length;
    final late = records.where((r) => r.status == 'late').length;
    final percentage = total == 0 ? 0 : ((present + late) / total) * 100;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
              "Overall", "${percentage.toStringAsFixed(1)}%", AppColors.accent),
          _statItem("Present", "$present", AppColors.success),
          _statItem("Absent", "${total - present - late}", AppColors.danger),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  /// Groups attendance records by enrolled course (subject offering), then
  /// by month within each course — a flat chronological list previously
  /// gave no way to see "how am I doing in Physics this month" at a glance.
  Widget _buildCourseGroupedView(
      List<ClassEntity> courses, List<AttendanceRecord> records) {
    final courseById = {for (final c in courses) c.id: c};
    final Map<String, List<AttendanceRecord>> byCourse = {};
    for (final r in records) {
      byCourse.putIfAbsent(r.classId, () => []).add(r);
    }
    // Show every currently-enrolled course even before it has any records.
    for (final c in courses) {
      byCourse.putIfAbsent(c.id, () => []);
    }

    if (byCourse.isEmpty) return _buildEmptyState();

    final courseIds = byCourse.keys.toList()
      ..sort((a, b) {
        final aLabel = courseById[a]?.displayLabel ?? a;
        final bLabel = courseById[b]?.displayLabel ?? b;
        return aLabel.compareTo(bLabel);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: courseIds
          .map((id) => _courseSection(courseById[id], id, byCourse[id]!))
          .toList(),
    );
  }

  Widget _courseSection(
      ClassEntity? course, String classId, List<AttendanceRecord> records) {
    final label = course?.displayLabel ?? 'Unknown Course';
    final total = records.length;
    final present = records.where((r) => r.isPresent).length;
    final late = records.where((r) => r.isLate).length;
    final pct = total == 0 ? 0.0 : ((present + late) / total) * 100;

    final Map<String, List<AttendanceRecord>> byMonth = {};
    for (final r in records) {
      byMonth
          .putIfAbsent(DateFormat('yyyy-MM').format(r.logDate), () => [])
          .add(r);
    }
    final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        initiallyExpanded: months.isNotEmpty,
        title: Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        subtitle: Text(
          total == 0
              ? 'No records yet'
              : '${pct.toStringAsFixed(1)}% overall · $total marked',
          style: const TextStyle(color: AppColors.accent, fontSize: 12),
        ),
        children: months.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text('No attendance recorded for this course yet.',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
              ]
            : months.map((m) => _monthSection(m, byMonth[m]!)).toList(),
      ),
    );
  }

  Widget _monthSection(String monthKey, List<AttendanceRecord> records) {
    final monthLabel =
        DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(monthKey));
    final total = records.length;
    final present = records.where((r) => r.isPresent).length;
    final late = records.where((r) => r.isLate).length;
    final absent = total - present - late;
    final pct = total == 0 ? 0.0 : ((present + late) / total) * 100;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(monthLabel,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              Text('${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: pct >= 75 ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Present $present · Late $late · Absent $absent',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 8),
          ...records.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _attendanceTile(r),
              )),
        ],
      ),
    );
  }

  Widget _attendanceTile(AttendanceRecord r) {
    Color statusColor;
    IconData icon;

    switch (r.status) {
      case 'present':
        statusColor = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'late':
        statusColor = AppColors.warning;
        icon = Icons.access_time_filled_rounded;
        break;
      default:
        statusColor = AppColors.danger;
        icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(r.logDate),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  "Marked on ${DateFormat('h:mm a').format(r.recordedAt)}",
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            r.status.toUpperCase(),
            style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text("No attendance records found.",
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
