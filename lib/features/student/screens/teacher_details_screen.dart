import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/class_entity.dart';
import '../../../data/models/shared_resource.dart';
import '../../../data/models/student_query.dart';
import '../../../data/models/attendance_record.dart';
import '../../../data/remote/classroom_service.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/attendance_provider.dart';
import '../../../widgets/gradient_background.dart';

class TeacherDetailsScreen extends StatefulWidget {
  final ClassEntity classEntity;
  const TeacherDetailsScreen({super.key, required this.classEntity});

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _classroomService = ClassroomService();
  final _queryCtrl = TextEditingController();
  bool _sendingQuery = false;

  DateTime _attendanceMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  Future<AttendanceMonthlyReport>? _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAttendanceMonth());
  }

  void _loadAttendanceMonth() {
    final user = context.read<AuthProvider>().currentUser;
    setState(() {
      _attendanceFuture = context.read<AttendanceProvider>().loadStudentMonthly(
            user?.uid ?? '',
            year: _attendanceMonth.year,
            month: _attendanceMonth.month,
          );
    });
  }

  void _shiftAttendanceMonth(int delta) {
    setState(() {
      _attendanceMonth =
          DateTime(_attendanceMonth.year, _attendanceMonth.month + delta);
    });
    _loadAttendanceMonth();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classEntity.primaryTeacherName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: context.appColors.textSecondary,
          tabs: const [
            Tab(text: 'RESOURCES'),
            Tab(text: 'ATTENDANCE'),
            Tab(text: 'DISCUSS'),
          ],
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildResourcesTab(),
              _buildAttendanceTab(),
              _buildDiscussTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourcesTab() {
    return StreamBuilder<List<SharedResource>>(
      stream: _classroomService.watchResources(
          widget.classEntity.id, widget.classEntity.academyId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
              child: Text('Error loading resources: ${snap.error}',
                  style: const TextStyle(color: AppColors.danger)));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return _emptyState(
              Icons.folder_open_rounded, "No resources shared yet.");
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _resourceCard(list[i]),
        );
      },
    );
  }

  Future<void> _openResourceLink(String url) async {
    final uri = Uri.tryParse(url);
    final ok = uri != null && await launchUrl(uri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open this link.")));
    }
  }

  Widget _resourceCard(SharedResource res) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(res.title,
                      style: TextStyle(
                          color: context.appColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16))),
            ],
          ),
          const SizedBox(height: 8),
          Text(res.description,
              style: TextStyle(
                  color: context.appColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MMM dd, yyyy').format(res.createdAt),
                  style: TextStyle(
                      color: context.appColors.textMuted, fontSize: 11)),
              if (res.fileUrl != null)
                TextButton.icon(
                  onPressed: () => _openResourceLink(res.fileUrl!),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text("View File",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.accent),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shows the student's overall attendance for the selected month (across
  /// every class, not just this teacher's) — the backend's monthly summary
  /// endpoint has no per-offering filter, only per-student.
  Widget _buildAttendanceTab() {
    return Column(
      children: [
        _attendanceMonthHeader(),
        Expanded(
          child: FutureBuilder<AttendanceMonthlyReport>(
            future: _attendanceFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                    child: Text('Error loading attendance: ${snap.error}',
                        style: const TextStyle(color: AppColors.danger)));
              }

              final report = snap.data!;
              if (report.records.isEmpty) {
                return _emptyState(Icons.fact_check_outlined,
                    "No attendance records found for this month.");
              }

              final records = report.records.reversed.toList();

              return Column(
                children: [
                  _attendanceSummaryHeader(report.summary),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _attendanceTile(records[i]),
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

  Widget _attendanceMonthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _shiftAttendanceMonth(-1),
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(_attendanceMonth),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _shiftAttendanceMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _attendanceSummaryHeader(AttendanceSummary summary) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.accent.withValues(alpha: 0.15),
          context.appColors.surface
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Attendance", "${summary.percentage.toStringAsFixed(1)}%",
              AppColors.accent),
          _statItem("Present", "${summary.presentCount}", AppColors.success),
          _statItem("Total Days", "${summary.totalDays}",
              context.appColors.textPrimary),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val, Color color) {
    return Column(
      children: [
        Text(val,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(label,
            style: TextStyle(
                color: context.appColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _attendanceTile(AttendanceDayRecord r) {
    final isPresent = r.status == 'present' || r.status == 'late';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.appColors.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('EEEE, MMM dd').format(r.logDate),
              style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w600)),
          Text(r.status.toUpperCase(),
              style: TextStyle(
                  color: isPresent ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w900,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDiscussTab() {
    final user = context.watch<AuthProvider>().currentUser;
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<StudentQuery>>(
            stream: _classroomService.watchQueriesForClass(
                widget.classEntity.id, widget.classEntity.academyId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                    child: Text('Error loading queries: ${snap.error}',
                        style: const TextStyle(color: AppColors.danger)));
              }
              final queries = (snap.data ?? [])
                  .where((q) => q.studentId == user?.uid)
                  .toList();
              if (queries.isEmpty) {
                return _emptyState(Icons.question_answer_outlined,
                    "Ask your teacher a question!");
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: queries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) => _queryCard(queries[i]),
              );
            },
          ),
        ),
        _queryInputArea(user),
      ],
    );
  }

  Widget _queryCard(StudentQuery q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16))),
          child: Text(q.question,
              style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w500)),
        ),
        if (q.answer != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 32),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: context.appColors.surface,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16)),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Teacher's Response",
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(q.answer!,
                      style: TextStyle(color: context.appColors.textPrimary)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _queryInputArea(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.appColors.surface,
          border: Border(top: BorderSide(color: context.appColors.border))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryCtrl,
              decoration: const InputDecoration(
                  hintText: "Type your query...",
                  border: InputBorder.none,
                  filled: false),
              style: TextStyle(color: context.appColors.textPrimary),
            ),
          ),
          IconButton(
            onPressed: _sendingQuery ? null : () => _submitQuery(user),
            icon: _sendingQuery
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent))
                : const Icon(Icons.send_rounded, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuery(dynamic user) async {
    if (_queryCtrl.text.trim().isEmpty || _sendingQuery) return;
    setState(() => _sendingQuery = true);
    try {
      await _classroomService.postQuery(
        offeringId: widget.classEntity.id,
        question: _queryCtrl.text.trim(),
      );
      _queryCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to send question: $e'),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _sendingQuery = false);
    }
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 48,
              color: context.appColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: context.appColors.textSecondary)),
        ],
      ),
    );
  }
}
