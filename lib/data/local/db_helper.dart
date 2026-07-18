import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Local SQLite database — used only for admin-side data that doesn't need
/// cross-device sync (fees + user management members).
/// Everything else (users auth, classes, attendance, announcements)
/// lives in Firestore.
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'taleemplus_v2.db'); // New DB name for fresh start with multi-tenancy
    return openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createMembers(db);
    await _createFeeInvoices(db);
  }

  Future<void> _createMembers(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS members (
        id          TEXT PRIMARY KEY,
        academy_id  TEXT NOT NULL,
        full_name   TEXT NOT NULL,
        email       TEXT,
        phone       TEXT,
        role        TEXT NOT NULL,
        extra       TEXT,
        status      TEXT NOT NULL DEFAULT 'active',
        created_at  TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createFeeInvoices(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fee_invoices (
        id                      TEXT PRIMARY KEY,
        academy_id              TEXT NOT NULL DEFAULT '',
        student_id              TEXT NOT NULL,
        student_name            TEXT NOT NULL,
        gross_amount_due        REAL NOT NULL,
        accumulated_amount_paid REAL NOT NULL DEFAULT 0,
        billing_month           TEXT NOT NULL,
        due_date                TEXT NOT NULL,
        paid_on                 TEXT,
        status                  TEXT NOT NULL DEFAULT 'unpaid',
        created_at              TEXT NOT NULL
      )
    ''');
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('members');
    await db.delete('fee_invoices');
  }
}