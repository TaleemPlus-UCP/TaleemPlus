import 'package:cloud_firestore/cloud_firestore.dart';

/// A monthly fee invoice for one student.
/// Maps to the `FeeLedgers` table in the SDS ERD (Figure 7).
class FeeInvoice {
  final String id;
  final String academyId;
  final String studentId;
  final String studentName;
  final double grossAmountDue;
  final double accumulatedAmountPaid;
  final String billingMonth;
  final DateTime dueDate;
  final DateTime? paidOn;
  final String status; // 'unpaid' | 'paid' | 'partial'
  final DateTime createdAt;

  const FeeInvoice({
    required this.id,
    required this.academyId,
    required this.studentId,
    required this.studentName,
    required this.grossAmountDue,
    this.accumulatedAmountPaid = 0,
    required this.billingMonth,
    required this.dueDate,
    this.paidOn,
    this.status = 'unpaid',
    required this.createdAt,
  });

  double get netBalanceDue => grossAmountDue - accumulatedAmountPaid;

  bool get isPaid => status == 'paid';
  bool get isPartial => status == 'partial';
  bool get isUnpaid => status == 'unpaid';

  /// Overdue = unpaid (or partial) AND past due date.
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toMap() => {
    'academy_id': academyId,
    'student_id': studentId,
    'student_name': studentName,
    'gross_amount_due': grossAmountDue,
    'accumulated_amount_paid': accumulatedAmountPaid,
    'billing_month': billingMonth,
    'due_date': Timestamp.fromDate(dueDate),
    'paid_on': paidOn != null ? Timestamp.fromDate(paidOn!) : null,
    'status': status,
    'created_at': Timestamp.fromDate(createdAt),
  };

  factory FeeInvoice.fromMap(String id, Map<String, dynamic> map) {
    return FeeInvoice(
      id: id,
      academyId: (map['academy_id'] ?? '') as String,
      studentId: (map['student_id'] ?? '') as String,
      studentName: (map['student_name'] ?? '') as String,
      grossAmountDue: (map['gross_amount_due'] as num?)?.toDouble() ?? 0,
      accumulatedAmountPaid:
      (map['accumulated_amount_paid'] as num?)?.toDouble() ?? 0,
      billingMonth: (map['billing_month'] ?? '') as String,
      dueDate: map['due_date'] is Timestamp 
          ? (map['due_date'] as Timestamp).toDate() 
          : DateTime.now(),
      paidOn: map['paid_on'] is Timestamp
          ? (map['paid_on'] as Timestamp).toDate()
          : null,
      status: (map['status'] ?? 'unpaid') as String,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  FeeInvoice copyWith({
    double? accumulatedAmountPaid,
    DateTime? paidOn,
    String? status,
  }) {
    return FeeInvoice(
      id: id,
      academyId: academyId,
      studentId: studentId,
      studentName: studentName,
      grossAmountDue: grossAmountDue,
      accumulatedAmountPaid:
      accumulatedAmountPaid ?? this.accumulatedAmountPaid,
      billingMonth: billingMonth,
      dueDate: dueDate,
      paidOn: paidOn ?? this.paidOn,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}