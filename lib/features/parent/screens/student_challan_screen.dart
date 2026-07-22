import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../widgets/gradient_background.dart';
import '../../../data/models/fee_challan_model.dart';
import '../../../data/repositories/fee_challan_repository.dart';
import '../../../data/remote/challan_pdf_service.dart';
import '../../../logic/auth_provider.dart';

class StudentChallanScreen extends StatefulWidget {
  final String studentUid;
  const StudentChallanScreen({super.key, required this.studentUid});

  @override
  State<StudentChallanScreen> createState() => _StudentChallanScreenState();
}

class _StudentChallanScreenState extends State<StudentChallanScreen> {
  final _repo = FeeChallanRepository();
  bool _loading = true;
  String? _errorMessage;
  FeeChallanModel? _latestChallan;
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadChallan();
  }

  Future<void> _loadChallan() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final academyId = Provider.of<AuthProvider>(context, listen: false)
              .currentUser
              ?.academyId ??
          '';

      // Passing the month and academyId to filter specifically
      final c = await _repo.getLatestForStudent(widget.studentUid, academyId,
          month: _selectedMonth);

      if (mounted) {
        setState(() {
          _latestChallan = c;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Challan',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildMonthFilter(),
              Expanded(
                child: _loading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent))
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _latestChallan == null
                            ? _buildEmptyState()
                            : _buildChallanDetails(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
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
              "Error loading challan: $_errorMessage",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChallan,
              child: const Text("RETRY"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: context.appColors.border.withValues(alpha: 0.5)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedMonth,
            isExpanded: true,
            dropdownColor: context.appColors.surfaceAlt,
            items: _months
                .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m,
                        style:
                            TextStyle(color: context.appColors.textPrimary))))
                .toList(),
            onChanged: (v) {
              setState(() => _selectedMonth = v!);
              _loadChallan();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChallanDetails() {
    if (_latestChallan == null) return _buildEmptyState();
    final c = _latestChallan!;
    final bool isOverdue = c.isOverdue;
    final statusColor = c.isPaid
        ? AppColors.success
        : (isOverdue ? AppColors.danger : AppColors.warning);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatusCard(c, statusColor),
        const SizedBox(height: 20),
        _buildDigitalPreview(c),
        const SizedBox(height: 24),
        _buildActionButtons(c),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStatusCard(FeeChallanModel c, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(
                c.isPaid
                    ? Icons.check_circle_rounded
                    : Icons.pending_actions_rounded,
                color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.status.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 16)),
                Text(
                    c.isPaid
                        ? "Payment received"
                        : "Due Date: ${DateFormat('dd MMM yyyy').format(c.dueDate)}",
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalPreview(FeeChallanModel c) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TOTAL PAYABLE",
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text("Rs. ${c.totalAmount.toStringAsFixed(0)}",
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
          const Divider(height: 32, color: AppColors.border),
          _previewRow("Student", c.studentName),
          _previewRow("Challan #", c.challanNumber),
          _previewRow("Monthly Fee", "Rs. ${c.monthlyFee}"),
          if (c.fine > 0) _previewRow("Fine", "Rs. ${c.fine}", isDanger: true),
          const SizedBox(height: 24),
          Center(
            child: QrImageView(
              data: "Challan:${c.challanNumber}|Student:${c.studentId}",
              version: QrVersions.auto,
              size: 100.0,
              eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square, color: AppColors.textPrimary),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String val, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(val,
              style: TextStyle(
                  color: isDanger ? AppColors.danger : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _handlePrint(FeeChallanModel c) async {
    try {
      await ChallanPdfService.generateAndPrint(c);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Print Error: $e"),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _handleShare(FeeChallanModel c) async {
    try {
      await ChallanPdfService.generateAndShare(c);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Share Error: $e"),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Widget _buildActionButtons(FeeChallanModel c) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showPaymentInstructions(c),
          icon: const Icon(Icons.payment_rounded),
          label: const Text("PAY NOW",
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textOnAccent,
            minimumSize: const Size(double.infinity, 56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handlePrint(c),
                icon: const Icon(Icons.print_rounded),
                label: const Text("PRINT"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleShare(c),
                icon: const Icon(Icons.share_rounded),
                label: const Text("SHARE"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPaymentInstructions(FeeChallanModel c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Payment Instructions",
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _instructionRow(Icons.account_balance_rounded, "Account Title",
                "Academy Management"),
            _instructionRow(
                Icons.numbers_rounded, "Account Number", "03014334151"),
            const SizedBox(height: 24),
            const Text("Future Support:",
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Opacity(
                    opacity: 0.5,
                    child: Text("JazzCash",
                        style: TextStyle(color: AppColors.textMuted))),
                Opacity(
                    opacity: 0.5,
                    child: Text("EasyPaisa",
                        style: TextStyle(color: AppColors.textMuted))),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _instructionRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
              Text(val,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
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
          Icon(Icons.receipt_long_rounded,
              size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text("No challans available for this month.",
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
