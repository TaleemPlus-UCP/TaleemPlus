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
    final path = p.join(dir, 'taleemplus.db');
    return openDatabase(
      path,
      version: 5, // bumped to drop classes/attendance tables
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createMembers(db);
    await _createFeeInvoices(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createFeeInvoices(db);
    if (oldVersion < 5) {
      // Classes / enrollments / attendance now live in Firestore.
      await db.execute('DROP TABLE IF EXISTS classes');
      await db.execute('DROP TABLE IF EXISTS class_enrollments');
      await db.execute('DROP TABLE IF EXISTS attendance_records');
    }
  }

  Future<void> _createMembers(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS members (
        id          TEXT PRIMARY KEY,
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