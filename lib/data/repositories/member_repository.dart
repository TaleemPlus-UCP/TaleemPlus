import '../local/db_helper.dart';
import '../models/academy_member.dart';

/// Bridges the UI and the local SQLite `members` table.
class MemberRepository {
  final DbHelper _dbHelper;
  MemberRepository({DbHelper? dbHelper})
      : _dbHelper = dbHelper ?? DbHelper.instance;

  Future<List<AcademyMember>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('members', orderBy: 'created_at DESC');
    return rows.map(AcademyMember.fromMap).toList();
  }

  Future<List<AcademyMember>> getByRole(String role) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'members',
      where: 'role = ?',
      whereArgs: [role],
      orderBy: 'created_at DESC',
    );
    return rows.map(AcademyMember.fromMap).toList();
  }

  Future<void> add(AcademyMember member) async {
    final db = await _dbHelper.database;
    await db.insert('members', member.toMap());
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> counts() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT role, COUNT(*) as c FROM members GROUP BY role',
    );
    final result = <String, int>{'teacher': 0, 'student': 0, 'parent': 0};
    for (final row in rows) {
      final role = row['role'] as String;
      result[role] = (row['c'] as int?) ?? 0;
    }
    return result;
  }
}