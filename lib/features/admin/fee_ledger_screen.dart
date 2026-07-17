import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/academy_member.dart';
import '../../data/models/fee_invoice.dart';
import '../../logic/fee_provider.dart';
import '../../logic/member_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';

final _currency = NumberFormat.currency(
    locale: 'en_PK', symbol: 'PKR ', decimalDigits: 0);

class FeeLedgerScreen extends StatefulWidget {
  const FeeLedgerScreen({super.key});

  @override
  State<FeeLedgerScreen> createState() => _FeeLedgerScreenState();
}

class _FeeLedgerScreenState extends State<FeeLedgerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeeProvider>().load();
      context.read<MemberProvider>().load();
    });
  }

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
          child: Consumer<FeeProvider>(
            builder: (context, fees, _) {
              if (fees.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              return RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () => fees.load(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  children: [
                    _statsRow(fees),
                    const SizedBox(height: 16),
                    _defaulterBanner(fees),
                    const SizedBox(height: 20),
                    const Text('INVOICES',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        )),
                    const SizedBox(height: 12),
                    if (fees.invoices.isEmpty)
                      _emptyState()
                    else
                      ...fees.invoices.map(_invoiceTile),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statsRow(FeeProvider fees) {
    return Row(
      children: [
        _statCard(
          label: 'Collected',
          value: _currency.format(fees.totalCollected),
          color: AppColors.success,
        ),
        const SizedBox(width: 10),
        _statCard(
          label: 'Pending',
          value: _currency.format(fees.totalPending),
          color: AppColors.warning,
        ),
        const SizedBox(width: 10),
        _statCard(
          label: 'Overdue',
          value: _currency.format(fees.totalOverdue),
          color: AppColors.danger,
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
  }) {
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
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

  Widget _defaulterBanner(FeeProvider fees) {
    if (fees.defaulterCount == 0) return const SizedBox.shrink();
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
            child: Text(
              '${fees.defaulterCount} student(s) with overdue payments',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
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

  Widget _invoiceTile(FeeInvoice inv) {
    final overdue = inv.isOverdue;
    final paid = inv.isPaid;
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
                      Text(inv.studentName,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('For ${inv.billingMonth}',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12)),
                    ],
                  ),
                ),
                _statusChip(inv),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _currency.format(inv.grossAmountDue),
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  'Due: ${DateFormat('d MMM yyyy').format(inv.dueDate)}',
                  style: TextStyle(
                    color: overdue
                        ? AppColors.danger
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                    overdue ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (!paid) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textOnAccent,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Mark as Paid'),
                      onPressed: () =>
                          context.read<FeeProvider>().markPaid(inv),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger),
                    onPressed: () => _confirmDelete(inv),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                'Paid on ${DateFormat('d MMM yyyy').format(inv.paidOn ?? inv.createdAt)}',
                style: const TextStyle(
                    color: AppColors.success, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(FeeInvoice inv) {
    late final String label;
    late final Color color;
    if (inv.isPaid) {
      label = 'PAID';
      color = AppColors.success;
    } else if (inv.isOverdue) {
      label = 'OVERDUE';
      color = AppColors.danger;
    } else {
      label = 'UNPAID';
      color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Future<void> _confirmDelete(FeeInvoice inv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        title: const Text('Delete invoice?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
            'Remove ${inv.studentName}\'s invoice for ${inv.billingMonth}?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<FeeProvider>().deleteInvoice(inv.id);
    }
  }

  void _openAddSheet() {
    final students = context.read<MemberProvider>().byRole('student');
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a student first from User Management.'),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddFeeSheet(students: students),
    );
  }
}

/// Bottom sheet to create a new fee invoice.
class _AddFeeSheet extends StatefulWidget {
  final List<AcademyMember> students;
  const _AddFeeSheet({required this.students});

  @override
  State<_AddFeeSheet> createState() => _AddFeeSheetState();
}

class _AddFeeSheetState extends State<_AddFeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  AcademyMember? _selectedStudent;
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
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    await context.read<FeeProvider>().addInvoice(
      studentId: _selectedStudent!.id,
      studentName: _selectedStudent!.fullName,
      amount: double.parse(_amountCtrl.text),
      billingMonth: DateFormat('yyyy-MM').format(_billingMonth),
      dueDate: _dueDate,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Invoice created for ${_selectedStudent!.fullName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Add Fee Invoice',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  )),
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
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AcademyMember>(
                    value: _selectedStudent,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceAlt,
                    hint: const Text('Select a student',
                        style: TextStyle(color: AppColors.textMuted)),
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: widget.students
                        .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.fullName),
                    ))
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
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(value,
                        style:
                        const TextStyle(color: AppColors.textPrimary)),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}