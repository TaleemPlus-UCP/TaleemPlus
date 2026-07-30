/// A monthly fee invoice for one student.
/// Maps to the `FeeLedgers` table in the SDS ERD (Figure 7).
class FeeInvoice {
  final String id;
  final String academyId; // NEW
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
    required this.academyId, // NEW
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
        'id': id,
        'academy_id': academyId, // NEW
        'student_id': studentId,
        'student_name': studentName,
        'gross_amount_due': grossAmountDue,
        'accumulated_amount_paid': accumulatedAmountPaid,
        'billing_month': billingMonth,
        'due_date': dueDate.toIso8601String(),
        'paid_on': paidOn?.toIso8601String(),
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory FeeInvoice.fromMap(Map<String, dynamic> map) {
    return FeeInvoice(
      id: map['id'] as String,
      academyId: (map['academy_id'] ?? '') as String, // NEW
      studentId: (map['student_id'] ?? '') as String,
      studentName: (map['student_name'] ?? '') as String,
      grossAmountDue: (map['gross_amount_due'] as num?)?.toDouble() ?? 0,
      accumulatedAmountPaid:
          (map['accumulated_amount_paid'] as num?)?.toDouble() ?? 0,
      billingMonth: (map['billing_month'] ?? '') as String,
      dueDate: DateTime.tryParse((map['due_date'] ?? '') as String) ??
          DateTime.now(),
      paidOn: (map['paid_on'] != null && (map['paid_on'] as String).isNotEmpty)
          ? DateTime.tryParse(map['paid_on'] as String)
          : null,
      status: (map['status'] ?? 'unpaid') as String,
      createdAt: DateTime.tryParse((map['created_at'] ?? '') as String) ??
          DateTime.now(),
    );
  }

  FeeInvoice copyWith({
    double? accumulatedAmountPaid,
    DateTime? paidOn,
    String? status,
  }) {
    return FeeInvoice(
      id: id,
      academyId: academyId, // NEW
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
