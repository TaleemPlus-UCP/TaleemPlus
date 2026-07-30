import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';
import '../../data/models/fee_challan_model.dart';
import '../../data/remote/api_exception.dart';
import '../../data/remote/auth_service.dart';
import '../../data/repositories/fee_challan_repository.dart';
import '../../logic/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';

final _currency =
    NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);

/// Ad-hoc, single-student fee tracking — backed by the same `/fee-challans`
/// API as the section-wide "Bulk Fee Challans" generator (see
/// `ChallanGenerationScreen`), just scoped to one hand-picked student at a
/// time via `POST /fee-challans` instead of a whole section.
class FeeLedgerScreen extends StatefulWidget {
  const FeeLedgerScreen({super.key});

  @override
  State<FeeLedgerScreen> createState() => _FeeLedgerScreenState();
}

class _FeeLedgerScreenState extends State<FeeLedgerScreen> {
  final _repo = FeeChallanRepository();
  List<FeeChallanModel> _challans = [];
  bool _loading = true;
  String? _error;
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final academyId =
          context.read<AuthProvider>().currentUser?.academyId ?? '';
      final challans = await _repo.getAll(academyId);
      if (!mounted) return;
      setState(() {
        _challans = challans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load fee records: $e';
        _loading = false;
      });
    }
  }

  double get _totalCollected =>
      _challans.where((c) => c.isPaid).fold(0, (sum, c) => sum + c.totalAmount);

  double get _totalPending => _challans
      .where((c) => !c.isPaid && !c.isOverdue)
      .fold(0, (sum, c) => sum + c.totalAmount);

  double get _totalOverdue => _challans
      .where((c) => c.isOverdue)
      .fold(0, (sum, c) => sum + c.totalAmount);

  int get _defaulterCount => _challans
      .where((c) => c.isOverdue)
      .map((c) => c.studentId)
      .toSet()
      .length;

  String _monthLabel(FeeChallanModel c) =>
      DateFormat('MMMM yyyy').format(DateTime(c.billingYear, c.billingMonth));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Fee Ledger',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Fee'),
        onPressed: _openAddSheet,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.danger),
                            const SizedBox(height: 12),
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    )
                  : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final filtered =
        _challans.where((c) => _monthLabel(c) == _selectedMonth).toList();

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
        children: [
          _buildMonthFilter(),
          const SizedBox(height: 16),
          _statsRow(),
          const SizedBox(height: 16),
          _defaulterBanner(),
          const SizedBox(height: 20),
          const Text('INVOICES',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            _emptyState()
          else
            ...filtered.map(_invoiceTile),
        ],
      ),
    );
  }

  Widget _buildMonthFilter() {
    final Set<String> availableMonths = _challans.map(_monthLabel).toSet();
    availableMonths.add(DateFormat('MMMM yyyy').format(DateTime.now()));
    final sortedMonths = availableMonths.toList()
      ..sort((a, b) => b.compareTo(a));

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          isExpanded: true,
          dropdownColor: AppColors.surfaceAlt,
          items: sortedMonths
              .map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(m,
                      style: const TextStyle(color: AppColors.textPrimary))))
              .toList(),
          onChanged: (v) => setState(() => _selectedMonth = v!),
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statCard(
            label: 'Collected',
            value: _currency.format(_totalCollected),
            color: AppColors.success),
        const SizedBox(width: 10),
        _statCard(
            label: 'Pending',
            value: _currency.format(_totalPending),
            color: AppColors.warning),
        const SizedBox(width: 10),
        _statCard(
            label: 'Overdue',
            value: _currency.format(_totalOverdue),
            color: AppColors.danger),
      ],
    );
  }

  Widget _statCard(
      {required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _defaulterBanner() {
    if (_defaulterCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$_defaulterCount student(s) with overdue payments',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('No invoices yet',
              style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Tap "Add Fee" to create the first invoice',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _invoiceTile(FeeChallanModel c) {
    final overdue = c.isOverdue;
    final paid = c.isPaid;
    final Color borderColor = paid
        ? AppColors.success.withValues(alpha: 0.5)
        : overdue
            ? AppColors.danger.withValues(alpha: 0.5)
            : AppColors.border.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.studentName,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('For ${_monthLabel(c)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                _statusChip(c),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(_currency.format(c.totalAmount),
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
                Text(
                  'Due: ${DateFormat('d MMM yyyy').format(c.dueDate)}',
                  style: TextStyle(
                    color: overdue ? AppColors.danger : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (!paid) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textOnAccent),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Mark as Paid'),
                onPressed: () => _markPaid(c),
              ),
            ] else ...[
              const SizedBox(height: 6),
              const Text('Paid',
                  style: TextStyle(color: AppColors.success, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(FeeChallanModel c) {
    late final String label;
    late final Color color;
    if (c.isPaid) {
      label = 'PAID';
      color = AppColors.success;
    } else if (c.isOverdue) {
      label = 'OVERDUE';
      color = AppColors.danger;
    } else {
      label = 'PENDING';
      color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Future<void> _markPaid(FeeChallanModel c) async {
    try {
      await _repo.updateStatus(c.id, 'paid');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  void _openAddSheet() async {
    final academyId = context.read<AuthProvider>().currentUser?.academyId ?? '';
    final students =
        await AuthService().getApprovedByRole(UserRole.student, academyId);
    if (!mounted) return;
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add a student first from User Management.')));
      return;
    }
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddFeeSheet(students: students, repo: _repo),
    );
    if (created == true) await _load();
  }
}

/// Bottom sheet to create a new ad-hoc fee challan for one student.
class _AddFeeSheet extends StatefulWidget {
  final List<AppUser> students;
  final FeeChallanRepository repo;
  const _AddFeeSheet({required this.students, required this.repo});

  @override
  State<_AddFeeSheet> createState() => _AddFeeSheetState();
}

class _AddFeeSheetState extends State<_AddFeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  AppUser? _selectedStudent;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));
  DateTime _billingMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select any date in the billing month',
    );
    if (picked != null) {
      setState(() => _billingMonth = DateTime(picked.year, picked.month));
    }
  }

  Future<void> _save() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a student')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await widget.repo.createSingle(
        studentId: _selectedStudent!.uid,
        billingYear: _billingMonth.year,
        billingMonth: _billingMonth.month,
        monthlyFee: double.parse(_amountCtrl.text),
        dueDate: _dueDate,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Invoice created for ${_selectedStudent!.fullName}')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppColors.danger));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to create invoice: $e'),
            backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 20, bottom: 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('Add Fee Invoice',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              const Text('Student',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AppUser>(
                    value: _selectedStudent,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceAlt,
                    hint: const Text('Select a student',
                        style: TextStyle(color: AppColors.textMuted)),
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: widget.students
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))))
                        .toList(),
                    onChanged: (s) => setState(() => _selectedStudent = s),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Amount (PKR)',
                hint: 'e.g. 4500',
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Amount is required';
                  final n = double.tryParse(t);
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              _pickerTile(
                label: 'Billing Month',
                value: DateFormat('MMMM yyyy').format(_billingMonth),
                icon: Icons.calendar_month_rounded,
                onTap: _pickMonth,
              ),
              const SizedBox(height: 12),
              _pickerTile(
                label: 'Due Date',
                value: DateFormat('d MMM yyyy').format(_dueDate),
                icon: Icons.event_rounded,
                onTap: _pickDueDate,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                  label: 'Create Invoice',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _saving ? null : _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerTile(
      {required String label,
      required String value,
      required IconData icon,
      required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(value,
                          style:
                              const TextStyle(color: AppColors.textPrimary))),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
