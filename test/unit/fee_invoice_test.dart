import 'package:flutter_test/flutter_test.dart';
import 'package:taleemplus_app/data/models/fee_invoice.dart';

void main() {
  group('FeeInvoice Model Tests', () {
    final now = DateTime.now();
    final dueDate = now.add(const Duration(days: 5));

    final testInvoice = FeeInvoice(
      id: 'inv_123',
      academyId: 'acad_001',
      studentId: 'std_456',
      studentName: 'John Doe',
      grossAmountDue: 5000.0,
      accumulatedAmountPaid: 2000.0,
      billingMonth: 'October 2023',
      dueDate: dueDate,
      createdAt: now,
      status: 'partial',
    );

    test('should calculate netBalanceDue correctly', () {
      expect(testInvoice.netBalanceDue, 3000.0);
    });

    test('should identify partial status correctly', () {
      expect(testInvoice.isPartial, true);
      expect(testInvoice.isPaid, false);
      expect(testInvoice.isUnpaid, false);
    });

    test('should not be overdue if current date is before due date', () {
      expect(testInvoice.isOverdue, false);
    });

    test('should be overdue if current date is after due date and not paid',
        () {
      final overdueInvoice = testInvoice.copyWith(
        status: 'unpaid',
      );
      // We need an invoice with a past due date to test this properly
      final pastInvoice = FeeInvoice(
        id: 'inv_old',
        academyId: 'acad_001',
        studentId: 'std_456',
        studentName: 'John Doe',
        grossAmountDue: 5000.0,
        billingMonth: 'September 2023',
        dueDate: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 10)),
        status: 'unpaid',
      );
      expect(pastInvoice.isOverdue, true);
    });

    test('fromMap and toMap should be consistent', () {
      final map = testInvoice.toMap();
      final fromMapInvoice = FeeInvoice.fromMap(map);

      expect(fromMapInvoice.id, testInvoice.id);
      expect(fromMapInvoice.grossAmountDue, testInvoice.grossAmountDue);
      expect(fromMapInvoice.netBalanceDue, testInvoice.netBalanceDue);
      expect(fromMapInvoice.status, testInvoice.status);
    });
  });
}
