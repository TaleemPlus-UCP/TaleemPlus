import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/models/fee_invoice.dart';
import '../data/repositories/fee_repository.dart';

/// Manages fee invoices + derived stats for the Admin.
class FeeProvider extends ChangeNotifier {
  final FeeRepository _repo;
  final _uuid = const Uuid();

  FeeProvider({FeeRepository? repo}) : _repo = repo ?? FeeRepository();

  List<FeeInvoice> _invoices = [];
  bool _loading = false;

  List<FeeInvoice> get invoices => _invoices;
  bool get loading => _loading;

  double get totalCollected =>
      _invoices.fold(0, (sum, i) => sum + i.accumulatedAmountPaid);

  double get totalPending => _invoices
      .where((i) => !i.isPaid && !i.isOverdue)
      .fold(0, (sum, i) => sum + i.netBalanceDue);

  double get totalOverdue => _invoices
      .where((i) => i.isOverdue)
      .fold(0, (sum, i) => sum + i.netBalanceDue);

  int get defaulterCount => _invoices
      .where((i) => i.isOverdue)
      .map((i) => i.studentId)
      .toSet()
      .length;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _invoices = await _repo.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> addInvoice({
    required String studentId,
    required String studentName,
    required double amount,
    required String billingMonth,
    required DateTime dueDate,
  }) async {
    final invoice = FeeInvoice(
      id: _uuid.v4(),
      studentId: studentId,
      studentName: studentName,
      grossAmountDue: amount,
      billingMonth: billingMonth,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    await _repo.add(invoice);
    await load();
  }

  Future<void> markPaid(FeeInvoice invoice) async {
    final updated = invoice.copyWith(
      accumulatedAmountPaid: invoice.grossAmountDue,
      paidOn: DateTime.now(),
      status: 'paid',
    );
    await _repo.update(updated);
    await load();
  }

  Future<void> deleteInvoice(String id) async {
    await _repo.delete(id);
    await load();
  }
}