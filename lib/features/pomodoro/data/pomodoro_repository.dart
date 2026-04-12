import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_service.dart';
import 'pomodoro_session_model.dart';

class PomodoroRepository {
  PomodoroRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<PomodoroSessionModel>> getSessions() async {
    final Database database = await _databaseService.database;
    final List<Map<String, Object?>> result = await database.rawQuery('''
      SELECT pomodoro_sessions.*, subjects.name as subject_name
      FROM pomodoro_sessions
      LEFT JOIN subjects ON subjects.id = pomodoro_sessions.subject_id
      ORDER BY pomodoro_sessions.completed_at DESC, pomodoro_sessions.id DESC
    ''');
    return result.map(PomodoroSessionModel.fromMap).toList();
  }

  Future<void> saveSession(PomodoroSessionModel session) async {
    final Database database = await _databaseService.database;
    await database.insert('pomodoro_sessions', session.toMap()..remove('id'));
  }
}
