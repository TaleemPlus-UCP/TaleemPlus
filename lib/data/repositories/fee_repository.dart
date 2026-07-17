import '../local/db_helper.dart';
import '../models/fee_invoice.dart';

class FeeRepository {
  final DbHelper _dbHelper;
  FeeRepository({DbHelper? dbHelper})
      : _dbHelper = dbHelper ?? DbHelper.instance;

  Future<List<FeeInvoice>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('fee_invoices', orderBy: 'created_at DESC');
    return rows.map(FeeInvoice.fromMap).toList();
  }

  Future<List<FeeInvoice>> getByStudent(String studentId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'fee_invoices',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'due_date DESC',
    );
    return rows.map(FeeInvoice.fromMap).toList();
  }

  Future<void> add(FeeInvoice invoice) async {
    final db = await _dbHelper.database;
    await db.insert('fee_invoices', invoice.toMap());
  }

  Future<void> update(FeeInvoice invoice) async {
    final db = await _dbHelper.database;
    await db.update(
      'fee_invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('fee_invoices', where: 'id = ?', whereArgs: [id]);
  }
}