import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_service.dart';
import 'semester_model.dart';

class SemesterRepository {
  SemesterRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<SemesterModel>> getSemesters() async {
    final Database database = await _databaseService.database;
    final List<Map<String, Object?>> result = await database.query(
      'semesters',
      orderBy: 'start_date DESC',
    );
    return result.map(SemesterModel.fromMap).toList();
  }

  Future<SemesterModel?> getActiveSemester() async {
    final Database database = await _databaseService.database;
    final List<Map<String, Object?>> result = await database.query(
      'semesters',
      where: 'is_active = ?',
      whereArgs: <Object?>[1],
      limit: 1,
    );
    if (result.isEmpty) {
      return null;
    }
    return SemesterModel.fromMap(result.first);
  }

  Future<void> saveSemester(SemesterModel semester) async {
    final Database database = await _databaseService.database;
    await database.transaction((Transaction txn) async {
      if (semester.isActive) {
        await txn.update('semesters', <String, Object?>{'is_active': 0});
      }

      if (semester.id == null) {
        await txn.insert('semesters', semester.toMap()..remove('id'));
      } else {
        await txn.update(
          'semesters',
          semester.toMap()..remove('id'),
          where: 'id = ?',
          whereArgs: <Object?>[semester.id],
        );
      }

      final List<Map<String, Object?>> countResult = await txn.rawQuery(
        'SELECT COUNT(*) as total, SUM(is_active) as active_total FROM semesters',
      );
      final int total = countResult.first['total'] as int? ?? 0;
      final int active = countResult.first['active_total'] as int? ?? 0;
      if (total > 0 && active == 0) {
        await txn.rawUpdate(
          'UPDATE semesters SET is_active = 1 WHERE id = (SELECT id FROM semesters ORDER BY start_date DESC LIMIT 1)',
        );
      }
    });
  }

  Future<void> setActiveSemester(int id) async {
    final Database database = await _databaseService.database;
    await database.transaction((Transaction txn) async {
      await txn.update('semesters', <String, Object?>{'is_active': 0});
      await txn.update(
        'semesters',
        <String, Object?>{'is_active': 1},
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    });
  }

  Future<void> deleteSemester(int id) async {
    final Database database = await _databaseService.database;
    await database.transaction((Transaction txn) async {
      await txn.delete(
        'semesters',
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );

      final List<Map<String, Object?>> remaining = await txn.query(
        'semesters',
        where: 'is_active = ?',
        whereArgs: <Object?>[1],
      );
      if (remaining.isEmpty) {
        await txn.rawUpdate(
          'UPDATE semesters SET is_active = 1 WHERE id = (SELECT id FROM semesters ORDER BY start_date DESC LIMIT 1)',
        );
      }
    });
  }
}
