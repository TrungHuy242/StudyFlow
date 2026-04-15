import '../../../core/database/database_service.dart';
import '../../../core/data/user_scope.dart';
import '../../../core/utils/database_value_utils.dart';
import 'schedule_model.dart';

class ScheduleRepository {
  ScheduleRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<ScheduleModel>> getSchedules() async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final List<dynamic> result = await _databaseService.client
        .from('schedules')
        .select('id, subject_id, weekday, start_time, end_time, room, type, subjects(name, color)')
        .gte('id', minId)
        .lt('id', maxId)
        .order('weekday')
        .order('start_time');
    return result
        .map((dynamic item) => _fromRow(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<ScheduleModel?> getScheduleById(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final dynamic result = await _databaseService.client
        .from('schedules')
        .select('id, subject_id, weekday, start_time, end_time, room, type, subjects(name, color)')
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id)
        .maybeSingle();
    if (result == null) {
      return null;
    }
    return _fromRow(Map<String, dynamic>.from(result as Map));
  }

  Future<void> saveSchedule(ScheduleModel schedule) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final Map<String, Object?> payload = <String, Object?>{
      'subject_id': schedule.subjectId,
      'weekday': schedule.weekday,
      'start_time': schedule.startTime,
      'end_time': schedule.endTime,
      'room': schedule.room,
      'type': schedule.type,
    };
    if (schedule.id == null) {
      await _databaseService.client.from('schedules').insert(<String, Object?>{
        'id': UserScope.generateId(userId),
        ...payload,
      });
      return;
    }

    await _databaseService.client
        .from('schedules')
        .update(payload)
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', schedule.id!);
  }

  Future<void> deleteSchedule(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    await _databaseService.client
        .from('schedules')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id);
  }

  ScheduleModel _fromRow(Map<String, dynamic> row) {
    final Map<String, dynamic>? subject =
        row['subjects'] is Map ? Map<String, dynamic>.from(row['subjects'] as Map) : null;
    return ScheduleModel.fromMap(<String, Object?>{
      'id': DatabaseValueUtils.asNullableInt(row['id']),
      'subject_id': DatabaseValueUtils.asInt(row['subject_id']),
      'subject_name': subject?['name'] as String?,
      'subject_color': subject?['color'] as String?,
      'weekday': DatabaseValueUtils.asInt(row['weekday']),
      'start_time': row['start_time']?.toString(),
      'end_time': row['end_time']?.toString(),
      'room': row['room'] as String?,
      'type': row['type'] as String?,
    });
  }
}
