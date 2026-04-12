import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_service.dart';
import 'deadline_model.dart';

class DeadlineRepository {
  DeadlineRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<DeadlineModel>> getDeadlines() async {
    final Database database = await _databaseService.database;
    final List<Map<String, Object?>> result = await database.rawQuery('''
      SELECT deadlines.*, subjects.name as subject_name, subjects.color as subject_color
      FROM deadlines
      LEFT JOIN subjects ON subjects.id = deadlines.subject_id
      ORDER BY deadlines.due_date ASC, deadlines.due_time ASC
    ''');
    return result.map(DeadlineModel.fromMap).toList();
  }

  Future<DeadlineModel?> getDeadlineById(int id) async {
    final List<DeadlineModel> deadlines = await getDeadlines();
    for (final DeadlineModel deadline in deadlines) {
      if (deadline.id == id) {
        return deadline;
      }
    }
    return null;
  }

  Future<void> saveDeadline(DeadlineModel deadline) async {
    final Database database = await _databaseService.database;
    if (deadline.id == null) {
      await database.insert('deadlines', deadline.toMap()..remove('id'));
      return;
    }

    await database.update(
      'deadlines',
      deadline.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[deadline.id],
    );
  }

  Future<void> deleteDeadline(int id) async {
    final Database database = await _databaseService.database;
    await database.delete(
      'deadlines',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
