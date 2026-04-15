import '../../../core/database/database_service.dart';
import '../../../core/data/user_scope.dart';
import '../../../core/utils/database_value_utils.dart';
import 'pomodoro_session_model.dart';

class PomodoroRepository {
  PomodoroRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<PomodoroSessionModel>> getSessions() async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final List<dynamic> result = await _databaseService.client
        .from('pomodoro_sessions')
        .select('id, subject_id, session_date, duration, type, completed_at, subjects(name)')
        .gte('id', minId)
        .lt('id', maxId)
        .order('completed_at', ascending: false)
        .order('id', ascending: false);
    return result
        .map((dynamic item) => _fromRow(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveSession(PomodoroSessionModel session) async {
    final String userId = _databaseService.requireUserId();
    await _databaseService.client.from('pomodoro_sessions').insert(<String, Object?>{
      'id': UserScope.generateId(userId),
      'subject_id': session.subjectId,
      'session_date': session.toMap()['session_date'],
      'duration': session.duration,
      'type': session.type,
      'completed_at': session.completedAt?.toUtc().toIso8601String(),
    });
  }

  PomodoroSessionModel _fromRow(Map<String, dynamic> row) {
    final Map<String, dynamic>? subject =
        row['subjects'] is Map ? Map<String, dynamic>.from(row['subjects'] as Map) : null;
    return PomodoroSessionModel.fromMap(<String, Object?>{
      'id': DatabaseValueUtils.asNullableInt(row['id']),
      'subject_id': DatabaseValueUtils.asNullableInt(row['subject_id']),
      'subject_name': subject?['name'] as String?,
      'session_date': row['session_date']?.toString(),
      'duration': DatabaseValueUtils.asInt(row['duration']),
      'type': row['type'] as String?,
      'completed_at': row['completed_at']?.toString(),
    });
  }
}
