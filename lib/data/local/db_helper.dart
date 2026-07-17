import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Central SQLite database for TaleemPlus (offline-first storage).
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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createMembers(db);
    await _createFeeInvoices(db);
    await _createClasses(db);
    await _createEnrollments(db);
    await _createAttendance(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createFeeInvoices(db);
    if (oldVersion < 3) {
      await _createClasses(db);
      await _createEnrollments(db);
    }
    if (oldVersion < 4) await _createAttendance(db);
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

  Future<void> _createClasses(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS classes (
        id                     TEXT PRIMARY KEY,
        class_name             TEXT NOT NULL,
        section                TEXT,
        subject                TEXT,
        primary_teacher_id     TEXT,
        primary_teacher_name   TEXT,
        primary_teacher_email  TEXT,
        created_at             TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createEnrollments(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS class_enrollments (
        id           TEXT PRIMARY KEY,
        class_id     TEXT NOT NULL,
        student_id   TEXT NOT NULL,
        student_name TEXT NOT NULL,
        enrolled_at  TEXT NOT NULL
      )
    ''');
  }

  /// Attendance: one row per student per class per date.
  /// Matches AttendanceRecords in SDS ERD (Figure 7).
  Future<void> _createAttendance(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance_records (
        id             TEXT PRIMARY KEY,
        class_id       TEXT NOT NULL,
        student_id     TEXT NOT NULL,
        student_name   TEXT NOT NULL,
        log_date       TEXT NOT NULL,
        status         TEXT NOT NULL,
        marked_by_uid  TEXT NOT NULL,
        recorded_at    TEXT NOT NULL,
        UNIQUE(class_id, student_id, log_date)
      )
    ''');
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('members');
    await db.delete('fee_invoices');
    await db.delete('classes');
    await db.delete('class_enrollments');
    await db.delete('attendance_records');
  }
}