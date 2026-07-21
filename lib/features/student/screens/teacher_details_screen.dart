import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
import '../../../widgets/app_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      stream: _classroomService.watchResources(widget.classEntity.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final list = snap.data ?? [];
        if (list.isEmpty)
          return _emptyState(
              Icons.folder_open_rounded, "No resources shared yet.");

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _resourceCard(list[i]),
        );
      },
    );
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
                  onPressed: () {}, // Link opening logic
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

  Widget _buildAttendanceTab() {
    final user = context.watch<AuthProvider>().currentUser;
    return StreamBuilder<List<AttendanceRecord>>(
      stream: context
          .read<AttendanceProvider>()
          .watchStudentAttendance(user?.uid ?? '', user?.academyId ?? ''),
      builder: (context, snap) {
        final allRecords = snap.data ?? [];
        // Filter specifically for this teacher's class
        final classRecords = allRecords
            .where((r) => r.classId == widget.classEntity.id)
            .toList();

        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (classRecords.isEmpty)
          return _emptyState(
              Icons.fact_check_outlined, "No attendance records found.");

        final total = classRecords.length;
        final present = classRecords
            .where((r) => r.status == 'present' || r.status == 'late')
            .length;
        final percentage = (present / total) * 100;

        return Column(
          children: [
            _attendanceSummaryHeader(percentage, present, total),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: classRecords.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _attendanceTile(classRecords[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _attendanceSummaryHeader(double pct, int p, int t) {
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
          _statItem("Subject Presence", "${pct.toStringAsFixed(1)}%",
              AppColors.accent),
          _statItem("Present", "$p", AppColors.success),
          _statItem("Total Classes", "$t", context.appColors.textPrimary),
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

  Widget _attendanceTile(AttendanceRecord r) {
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
            stream:
                _classroomService.watchQueriesForClass(widget.classEntity.id),
            builder: (context, snap) {
              final queries = (snap.data ?? [])
                  .where((q) => q.studentId == user?.uid)
                  .toList();
              if (queries.isEmpty)
                return _emptyState(Icons.question_answer_outlined,
                    "Ask your teacher a question!");

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
            onPressed: () => _submitQuery(user),
            icon: const Icon(Icons.send_rounded, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuery(dynamic user) async {
    if (_queryCtrl.text.trim().isEmpty) return;
    final q = StudentQuery(
      id: '', // Firestore auto-gen
      academyId: user.academyId,
      classId: widget.classEntity.id,
      studentId: user.uid,
      studentName: user.fullName,
      teacherId: widget.classEntity.primaryTeacherId,
      question: _queryCtrl.text,
      createdAt: DateTime.now(),
    );
    await _classroomService.postQuery(q);
    _queryCtrl.clear();
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
