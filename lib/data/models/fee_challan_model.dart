import 'package:cloud_firestore/cloud_firestore.dart';

class FeeChallanModel {
  final String id;
  final String academyId; // NEW
  final String challanNumber;
  final String studentId;
  final String studentName;
  final String fatherName;
  final String classLabel;
  final String rollNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final double monthlyFee;
  final double admissionFee;
  final double examFee;
  final double transportFee;
  final double fine;
  final String status; // 'pending', 'paid', 'overdue'
  final DateTime createdAt;
  final DateTime updatedAt;

  FeeChallanModel({
    required this.id,
    required this.academyId, // NEW
    required this.challanNumber,
    required this.studentId,
    required this.studentName,
    required this.fatherName,
    required this.classLabel,
    required this.rollNumber,
    required this.issueDate,
    required this.dueDate,
    required this.monthlyFee,
    required this.admissionFee,
    required this.examFee,
    required this.transportFee,
    required this.fine,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAmount =>
      monthlyFee + admissionFee + examFee + transportFee + fine;

  bool get isPaid => status == 'paid';
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toMap() {
    return {
      'academy_id': academyId,
      'challan_number': challanNumber,
      'student_id': studentId,
      'student_name': studentName,
      'father_name': fatherName,
      'class_label': classLabel,
      'roll_number': rollNumber,
      'issue_date': Timestamp.fromDate(issueDate),
      'due_date': Timestamp.fromDate(dueDate),
      'monthly_fee': monthlyFee,
      'admission_fee': admissionFee,
      'exam_fee': examFee,
      'transport_fee': transportFee,
      'fine': fine,
      'total_amount': totalAmount,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  factory FeeChallanModel.fromMap(String id, Map<String, dynamic> map) {
    return FeeChallanModel(
      id: id,
      academyId: (map['academy_id'] ?? '') as String,
      challanNumber: map['challan_number'] ?? '',
      studentId: map['student_id'] ?? '',
      studentName: map['student_name'] ?? '',
      fatherName: map['father_name'] ?? '',
      classLabel: map['class_label'] ?? '',
      rollNumber: map['roll_number'] ?? '',
      issueDate: map['issue_date'] is Timestamp
          ? (map['issue_date'] as Timestamp).toDate()
          : DateTime.now(),
      dueDate: map['due_date'] is Timestamp
          ? (map['due_date'] as Timestamp).toDate()
          : DateTime.now(),
      monthlyFee: (map['monthly_fee'] ?? 0).toDouble(),
      admissionFee: (map['admission_fee'] ?? 0).toDouble(),
      examFee: (map['exam_fee'] ?? 0).toDouble(),
      transportFee: (map['transport_fee'] ?? 0).toDouble(),
      fine: (map['fine'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updated_at'] is Timestamp
          ? (map['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
