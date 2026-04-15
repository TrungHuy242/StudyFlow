import '../../../core/database/database_service.dart';
import '../../../core/data/user_scope.dart';
import '../../../core/utils/database_value_utils.dart';
import 'deadline_model.dart';

class DeadlineRepository {
  DeadlineRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<DeadlineModel>> getDeadlines() async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final List<dynamic> result = await _databaseService.client
        .from('deadlines')
        .select('id, subject_id, title, description, due_date, due_time, priority, status, progress, subjects(name, color)')
        .gte('id', minId)
        .lt('id', maxId)
        .order('due_date')
        .order('due_time');
    return result
        .map((dynamic item) => _fromRow(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<DeadlineModel?> getDeadlineById(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final dynamic result = await _databaseService.client
        .from('deadlines')
        .select('id, subject_id, title, description, due_date, due_time, priority, status, progress, subjects(name, color)')
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id)
        .maybeSingle();
    if (result == null) {
      return null;
    }
    return _fromRow(Map<String, dynamic>.from(result as Map));
  }

  Future<void> saveDeadline(DeadlineModel deadline) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final Map<String, Object?> payload = <String, Object?>{
      'subject_id': deadline.subjectId,
      'title': deadline.title,
      'description': deadline.description,
      'due_date': deadline.toMap()['due_date'],
      'due_time': deadline.dueTime,
      'priority': deadline.priority,
      'status': deadline.status,
      'progress': deadline.progress,
    };
    if (deadline.id == null) {
      await _databaseService.client.from('deadlines').insert(<String, Object?>{
        'id': UserScope.generateId(userId),
        ...payload,
      });
      return;
    }

    await _databaseService.client
        .from('deadlines')
        .update(payload)
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', deadline.id!);
  }

  Future<void> deleteDeadline(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    await _databaseService.client
        .from('deadlines')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id);
  }

  DeadlineModel _fromRow(Map<String, dynamic> row) {
    final Map<String, dynamic>? subject =
        row['subjects'] is Map ? Map<String, dynamic>.from(row['subjects'] as Map) : null;
    return DeadlineModel.fromMap(<String, Object?>{
      'id': DatabaseValueUtils.asNullableInt(row['id']),
      'subject_id': DatabaseValueUtils.asNullableInt(row['subject_id']),
      'subject_name': subject?['name'] as String?,
      'subject_color': subject?['color'] as String?,
      'title': row['title'] as String?,
      'description': row['description'] as String?,
      'due_date': row['due_date']?.toString(),
      'due_time': row['due_time']?.toString(),
      'priority': row['priority'] as String?,
      'status': row['status'] as String?,
      'progress': DatabaseValueUtils.asInt(row['progress']),
    });
  }
}
