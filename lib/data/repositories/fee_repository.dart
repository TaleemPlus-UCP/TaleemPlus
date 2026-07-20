import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_invoice.dart';

class FeeRepository {
  final FirebaseFirestore _db;
  FeeRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('fee_invoices');

  Future<List<FeeInvoice>> getAll(String academyId) async {
    final snap = await _col
        .where('academy_id', isEqualTo: academyId)
        .get();
    
    final list = snap.docs
        .map((d) => FeeInvoice.fromMap(d.id, d.data()))
        .toList();
    
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<FeeInvoice>> getByStudent(String studentId, String academyId) async {
    final snap = await _col
        .where('academy_id', isEqualTo: academyId)
        .where('student_id', isEqualTo: studentId)
        .get();

    final list = snap.docs
        .map((d) => FeeInvoice.fromMap(d.id, d.data()))
        .toList();

    list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return list;
  }

  Future<void> add(FeeInvoice invoice) async {
    await _col.doc(invoice.id).set(invoice.toMap());
  }

  Future<void> update(FeeInvoice invoice) async {
    await _col.doc(invoice.id).update(invoice.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}