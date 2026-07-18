import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';
import '../../../data/remote/auth_service.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/class_provider.dart';
import '../../../data/models/fee_challan_model.dart';
import '../../../data/repositories/fee_challan_repository.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/app_widgets.dart';

class ChallanGenerationScreen extends StatefulWidget {
  const ChallanGenerationScreen({super.key});

  @override
  State<ChallanGenerationScreen> createState() => _ChallanGenerationScreenState();
}

class _ChallanGenerationScreenState extends State<ChallanGenerationScreen> {
  final _repo = FeeChallanRepository();
  String? _selectedClassId;
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  final _monthlyFeeCtrl = TextEditingController(text: "3000");
  final _admissionFeeCtrl = TextEditingController(text: "0");
  final _examFeeCtrl = TextEditingController(text: "0");
  final _fineCtrl = TextEditingController(text: "0");
  
  bool _isGenerating = false;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassProvider>().classes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Challans', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildClassSelector(classes),
              const SizedBox(height: 16),
              _buildMonthSelector(),
              const SizedBox(height: 24),
              const Text("FEE STRUCTURE", style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              LabeledField(label: "Monthly Tuition Fee", hint: "3000", controller: _monthlyFeeCtrl, keyboardType: TextInputType.number),
              LabeledField(label: "Admission Fee (One-time)", hint: "0", controller: _admissionFeeCtrl, keyboardType: TextInputType.number),
              LabeledField(label: "Exam Fee", hint: "0", controller: _examFeeCtrl, keyboardType: TextInputType.number),
              LabeledField(label: "Fine / Arrears", hint: "0", controller: _fineCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              PrimaryButton(
                label: "GENERATE FOR ENTIRE CLASS",
                icon: Icons.auto_awesome_motion_rounded,
                loading: _isGenerating,
                onPressed: _selectedClassId == null ? null : _generateChallans,
              ),
              const SizedBox(height: 12),
              const Text("Note: This will create pending challans for all students enrolled in the selected class.", 
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector(List<dynamic> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SELECT CLASS", style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedClassId,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              hint: const Text("Pick a class"),
              items: classes.map((c) => DropdownMenuItem(value: c.id as String, child: Text(c.displayLabel as String, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
              onChanged: (v) => setState(() => _selectedClassId = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("BILLING MONTH", style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMonth,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
              onChanged: (v) => setState(() => _selectedMonth = v!),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateChallans() async {
    setState(() => _isGenerating = true);
    
    try {
      final cp = context.read<ClassProvider>();
      final cls = cp.classes.firstWhere((c) => c.id == _selectedClassId);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final admin = auth.currentUser;
      if (admin == null) return;

      if (cls.studentIds.isEmpty) {
        throw Exception("No students are enrolled in this class.");
      }

      // Fetching all approved students from Firebase to ensure we have father names/extra data
      final authService = AuthService();
      final allStudents = await authService.getApprovedByRole(UserRole.student, admin.uid);
      
      int count = 0;
      for (var studentId in cls.studentIds) {
        // Find student in our fresh list, or fallback to class records
        final student = allStudents.firstWhere(
          (s) => s.uid == studentId, 
          orElse: () => AppUser(
            uid: studentId, 
            fullName: cls.studentNames[studentId] ?? "Student", 
            email: "", 
            phoneNumber: "", 
            role: UserRole.student,
            academyName: "N/A",
            academyId: admin.uid,
          )
        );

        final challan = FeeChallanModel(
          id: const Uuid().v4(),
          academyId: admin.uid,
          challanNumber: "CH-${_selectedMonth.substring(0,3).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
          studentId: studentId,
          studentName: student.fullName,
          fatherName: student.academyName ?? "N/A", // We reuse academyName for student bio sometimes
          classLabel: cls.displayLabel,
          rollNumber: cls.id.substring(0,4), // Fallback or extra data
          issueDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 10)),
          monthlyFee: double.tryParse(_monthlyFeeCtrl.text) ?? 0,
          admissionFee: double.tryParse(_admissionFeeCtrl.text) ?? 0,
          examFee: double.tryParse(_examFeeCtrl.text) ?? 0,
          transportFee: 0,
          fine: double.tryParse(_fineCtrl.text) ?? 0,
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _repo.createChallan(challan);
        count++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully generated $count challans for $_selectedMonth!"), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Generation failed: $e"), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
