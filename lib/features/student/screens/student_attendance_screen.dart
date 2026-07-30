import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/attendance_provider.dart';
import '../../../widgets/gradient_background.dart';
import '../../../data/models/attendance_record.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String studentUid;
  const StudentAttendanceScreen({super.key, required this.studentUid});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedYear = DateTime.now().year;

  Future<AttendanceMonthlyReport>? _monthlyFuture;
  Future<AttendanceYearlyReport>? _yearlyFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMonth();
    _loadYear();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMonth() {
    setState(() {
      _monthlyFuture = context.read<AttendanceProvider>().loadStudentMonthly(
            widget.studentUid,
            year: _selectedMonth.year,
            month: _selectedMonth.month,
          );
    });
  }

  void _loadYear() {
    setState(() {
      _yearlyFuture = context.read<AttendanceProvider>().loadStudentYearly(
            widget.studentUid,
            year: _selectedYear,
          );
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadMonth();
  }

  void _shiftYear(int delta) {
    setState(() => _selectedYear += delta);
    _loadYear();
  }

  void _jumpToMonth(int month) {
    setState(() {
      _selectedMonth = DateTime(_selectedYear, month);
      _tabController.index = 0;
    });
    _loadMonth();
  }

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [Tab(text: 'Month'), Tab(text: 'Year')],
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: academyId.isEmpty
              ? const Center(child: Text("Academy session error"))
              : TabBarView(
                  controller: _tabController,
                  children: [_monthTab(), _yearTab()],
                ),
        ),
      ),
    );
  }

  // ---------- Month tab ----------

  Widget _monthTab() {
    return Column(
      children: [
        _monthHeader(),
        Expanded(
          child: FutureBuilder<AttendanceMonthlyReport>(
            future: _monthlyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }
              if (snapshot.hasError) {
                return _errorState("Error loading records: ${snapshot.error}");
              }

              final report = snapshot.data!;
              if (report.records.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  _buildStatsHeader(report.summary),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: report.records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _attendanceTile(
                          report.records[report.records.length - 1 - index]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _monthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppColors.textSecondary),
            onPressed: () => _shiftMonth(-1),
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
            onPressed: () => _shiftMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(AttendanceSummary summary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Overall", "${summary.percentage.toStringAsFixed(1)}%",
              AppColors.accent),
          _statItem("Present", "${summary.presentCount}", AppColors.success),
          _statItem("Absent", "${summary.absentCount}", AppColors.danger),
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

  Widget _attendanceTile(AttendanceDayRecord r) {
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
                shape: BoxShape.circle),
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
                if (r.recordedAt != null)
                  Text(
                    "Marked on ${DateFormat('h:mm a').format(r.recordedAt!)}",
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
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

  // ---------- Year tab ----------

  Widget _yearTab() {
    return Column(
      children: [
        _yearHeader(),
        Expanded(
          child: FutureBuilder<AttendanceYearlyReport>(
            future: _yearlyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }
              if (snapshot.hasError) {
                return _errorState(
                    "Error loading yearly summary: ${snapshot.error}");
              }

              final report = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: report.months.length,
                itemBuilder: (context, index) =>
                    _monthCard(report.months[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _yearHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppColors.textSecondary),
            onPressed: () => _shiftYear(-1),
          ),
          Expanded(
            child: Text(
              '$_selectedYear',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
            onPressed: () => _shiftYear(1),
          ),
        ],
      ),
    );
  }

  Widget _monthCard(AttendanceMonthSummary entry) {
    final hasData = entry.summary.totalDays > 0;
    final color = !hasData
        ? AppColors.textMuted
        : entry.summary.percentage >= 75
            ? AppColors.success
            : entry.summary.percentage >= 50
                ? AppColors.warning
                : AppColors.danger;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _jumpToMonth(entry.month),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM').format(DateTime(_selectedYear, entry.month)),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
            Text(
              hasData ? '${entry.summary.percentage.toStringAsFixed(0)}%' : '—',
              style: TextStyle(
                  color: color, fontSize: 26, fontWeight: FontWeight.w900),
            ),
            Text(
              hasData
                  ? '${entry.summary.presentCount + entry.summary.lateCount}/${entry.summary.totalDays} days'
                  : 'No records',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Shared ----------

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger)),
          ],
        ),
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
          Text("No attendance records found for this month.",
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
