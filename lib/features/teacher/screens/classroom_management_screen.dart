import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/class_entity.dart';
import '../../../data/models/shared_resource.dart';
import '../../../data/models/student_query.dart';
import '../../../data/remote/classroom_service.dart';
import '../../../logic/auth_provider.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/app_widgets.dart';

class ClassroomManagementScreen extends StatefulWidget {
  final ClassEntity classEntity;
  const ClassroomManagementScreen({super.key, required this.classEntity});

  @override
  State<ClassroomManagementScreen> createState() => _ClassroomManagementScreenState();
}

class _ClassroomManagementScreenState extends State<ClassroomManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _classroomService = ClassroomService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classEntity.displayLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: context.appColors.textSecondary,
          tabs: const [
            Tab(text: 'STUDENT QUERIES'),
            Tab(text: 'SHARE CONTENT'),
          ],
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildQueriesTab(),
              _buildShareTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueriesTab() {
    return StreamBuilder<List<StudentQuery>>(
      stream: _classroomService.watchQueriesForClass(widget.classEntity.id),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (list.isEmpty) return _emptyState(Icons.question_answer_outlined, "No pending student queries.");

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _queryTile(list[i]),
        );
      },
    );
  }

  Widget _queryTile(StudentQuery q) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: q.isResolved ? AppColors.success.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 12, child: Text(q.studentName[0], style: const TextStyle(fontSize: 10))),
              const SizedBox(width: 8),
              Text(q.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              if (q.isResolved) const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(q.question, style: TextStyle(color: context.appColors.textPrimary, fontSize: 14)),
          if (q.answer != null) ...[
            const Divider(height: 24),
            Text("My Response: ${q.answer}", style: const TextStyle(color: AppColors.success, fontSize: 13, fontStyle: FontStyle.italic)),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: PrimaryButton(
                label: "REPLY", 
                onPressed: () => _showReplyDialog(q),
                icon: Icons.reply_rounded,
              ),
            ),
        ],
      ),
    );
  }

  void _showReplyDialog(StudentQuery q) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reply to Student"),
        content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: "Enter your answer...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(onPressed: () async {
            if (ctrl.text.isEmpty) return;
            await _classroomService.answerQuery(q.id, ctrl.text);
            if (mounted) Navigator.pop(ctx);
          }, child: const Text("SEND")),
        ],
      ),
    );
  }

  Widget _buildShareTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: PrimaryButton(
            label: "UPLOAD NEW RESOURCE", 
            icon: Icons.upload_file_rounded,
            onPressed: _showUploadSheet,
          ),
        ),
        Expanded(
          child: StreamBuilder<List<SharedResource>>(
            stream: _classroomService.watchResources(widget.classEntity.id),
            builder: (context, snap) {
              final list = snap.data ?? [];
              if (list.isEmpty) return _emptyState(Icons.folder_open_rounded, "You haven't shared any content yet.");
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => ListTile(
                  tileColor: context.appColors.surface.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(list[i].title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(list[i].description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.description_rounded, color: AppColors.accent),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showUploadSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Share Study Material", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            LabeledField(label: "Title", hint: "e.g. Physics Chapter 1 Notes", controller: titleCtrl),
            LabeledField(label: "Description", hint: "Summary or instructions...", controller: descCtrl),
            const SizedBox(height: 20),
            PrimaryButton(label: "POST TO CLASS", onPressed: () async {
              final user = context.read<AuthProvider>().currentUser;
              final res = SharedResource(
                id: '', 
                academyId: user!.academyId!,
                classId: widget.classEntity.id,
                teacherId: user.uid,
                teacherName: user.fullName,
                title: titleCtrl.text,
                description: descCtrl.text,
                createdAt: DateTime.now(),
              );
              await _classroomService.uploadResource(res);
              if (mounted) Navigator.pop(ctx);
            }),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: context.appColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: context.appColors.textSecondary)),
        ],
      ),
    );
  }
}
