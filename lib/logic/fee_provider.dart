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

  Future<void> load(String academyId) async {
    _loading = true;
    notifyListeners();
    _invoices = await _repo.getAll(academyId);
    _loading = false;
    notifyListeners();
  }

  Future<void> addInvoice({
    required String studentId,
    required String studentName,
    required double amount,
    required String billingMonth,
    required DateTime dueDate,
    required String academyId, // NEW
  }) async {
    final invoice = FeeInvoice(
      id: _uuid.v4(),
      academyId: academyId, // NEW
      studentId: studentId,
      studentName: studentName,
      grossAmountDue: amount,
      billingMonth: billingMonth,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    await _repo.add(invoice);
    await load(academyId);
  }

  Future<void> markPaid(FeeInvoice invoice) async {
    final updated = invoice.copyWith(
      accumulatedAmountPaid: invoice.grossAmountDue,
      paidOn: DateTime.now(),
      status: 'paid',
    );
    await _repo.update(updated);
    await load(invoice.academyId);
  }

  Future<void> deleteInvoice(String id, String academyId) async {
    await _repo.delete(id);
    await load(academyId);
  }

  /// NEW: Fetches fee history for a specific student in an academy.
  Future<List<FeeInvoice>> getStudentFees(
      String studentId, String academyId) async {
    return await _repo.getByStudent(studentId, academyId);
  }
}
