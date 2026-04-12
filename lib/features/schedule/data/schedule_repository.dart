import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_service.dart';
import 'schedule_model.dart';

class ScheduleRepository {
  ScheduleRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<ScheduleModel>> getSchedules() async {
    final Database database = await _databaseService.database;
    final List<Map<String, Object?>> result = await database.rawQuery('''
      SELECT schedules.*, subjects.name as subject_name, subjects.color as subject_color
      FROM schedules
      INNER JOIN subjects ON subjects.id = schedules.subject_id
      ORDER BY schedules.weekday ASC, schedules.start_time ASC
    ''');
    return result.map(ScheduleModel.fromMap).toList();
  }

  Future<ScheduleModel?> getScheduleById(int id) async {
    final List<ScheduleModel> schedules = await getSchedules();
    for (final ScheduleModel schedule in schedules) {
      if (schedule.id == id) {
        return schedule;
      }
    }
    return null;
  }

  Future<void> saveSchedule(ScheduleModel schedule) async {
    final Database database = await _databaseService.database;
    if (schedule.id == null) {
      await database.insert('schedules', schedule.toMap()..remove('id'));
      return;
    }

    await database.update(
      'schedules',
      schedule.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[schedule.id],
    );
  }

  Future<void> deleteSchedule(int id) async {
    final Database database = await _databaseService.database;
    await database.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
