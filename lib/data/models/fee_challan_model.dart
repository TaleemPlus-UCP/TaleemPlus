class FeeChallanModel {
  final String id;
  final String academyId;
  final String challanNumber;
  final String studentId;
  final String studentName;
  final String fatherName; // not modeled by the backend; always empty
  final String classLabel;
  final String
      rollNumber; // best-effort: the student's free-text extraInfo note
  final int billingYear;
  final int billingMonth;
  final DateTime issueDate;
  final DateTime dueDate;
  final double monthlyFee;
  final double admissionFee;
  final double examFee;
  final double transportFee;
  final double fine;
  final double totalAmount;
  final String status; // 'pending' | 'paid' | 'overdue'
  final DateTime createdAt;
  final DateTime updatedAt;

  FeeChallanModel({
    required this.id,
    required this.academyId,
    required this.challanNumber,
    required this.studentId,
    required this.studentName,
    this.fatherName = '',
    required this.classLabel,
    this.rollNumber = '',
    required this.billingYear,
    required this.billingMonth,
    required this.issueDate,
    required this.dueDate,
    required this.monthlyFee,
    required this.admissionFee,
    required this.examFee,
    required this.transportFee,
    required this.fine,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => status == 'paid';

  /// Computed client-side (the backend never auto-flips status past the due
  /// date) rather than trusting a stored 'overdue' status, matching the
  /// original app's behavior.
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);

  factory FeeChallanModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    return FeeChallanModel(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      challanNumber: json['challanNumber'] as String,
      studentId: (student?['id'] as String?) ?? '',
      studentName: (student?['fullName'] as String?) ?? 'Student',
      classLabel: (json['classLabelSnapshot'] as String?) ?? '',
      rollNumber: (student?['extraInfo'] as String?) ?? '',
      billingYear: json['billingYear'] as int,
      billingMonth: json['billingMonth'] as int,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      monthlyFee: (json['monthlyFee'] as num).toDouble(),
      admissionFee: (json['admissionFee'] as num).toDouble(),
      examFee: (json['examFee'] as num).toDouble(),
      transportFee: (json['transportFee'] as num).toDouble(),
      fine: (json['fine'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: (json['status'] as String).toLowerCase(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
