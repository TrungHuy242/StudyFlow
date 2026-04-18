import '../../../core/database/database_service.dart';
import '../../../core/data/user_scope.dart';
import '../../../core/utils/database_value_utils.dart';
import 'study_plan_model.dart';

class StudyPlanRepository {
  StudyPlanRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<StudyPlanModel>> getPlans() async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final List<dynamic> result = await _databaseService.client
        .from('study_plans')
        .select('id, subject_id, title, plan_date, start_time, end_time, duration, topic, status, subjects(name, color)')
        .gte('id', minId)
        .lt('id', maxId)
        .order('plan_date')
        .order('start_time');
    return result
        .map((dynamic item) => _fromRow(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<StudyPlanModel?> getPlanById(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final dynamic result = await _databaseService.client
        .from('study_plans')
        .select('id, subject_id, title, plan_date, start_time, end_time, duration, topic, status, subjects(name, color)')
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id)
        .maybeSingle();
    if (result == null) {
      return null;
    }
    return _fromRow(Map<String, dynamic>.from(result as Map));
  }

  Future<void> savePlan(StudyPlanModel plan) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final Map<String, Object?> payload = <String, Object?>{
      'subject_id': plan.subjectId,
      'title': plan.title,
      'plan_date': plan.toMap()['plan_date'],
      'start_time': plan.startTime,
      'end_time': plan.endTime,
      'duration': plan.duration,
      'topic': plan.topic,
      'status': plan.status,
    };
    if (plan.id == null) {
      await _databaseService.client.from('study_plans').insert(<String, Object?>{
        'id': UserScope.generateId(userId),
        ...payload,
      });
      return;
    }

    await _databaseService.client
        .from('study_plans')
        .update(payload)
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', plan.id!);
  }

  Future<void> deletePlan(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    await _databaseService.client
        .from('study_plans')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id);
  }

  StudyPlanModel _fromRow(Map<String, dynamic> row) {
    final Map<String, dynamic>? subject =
        row['subjects'] is Map ? Map<String, dynamic>.from(row['subjects'] as Map) : null;
    return StudyPlanModel.fromMap(<String, Object?>{
      'id': DatabaseValueUtils.asNullableInt(row['id']),
      'subject_id': DatabaseValueUtils.asNullableInt(row['subject_id']),
      'subject_name': subject?['name'] as String?,
      'subject_color': subject?['color'] as String?,
      'title': row['title'] as String?,
      'plan_date': row['plan_date']?.toString(),
      'start_time': row['start_time']?.toString(),
      'end_time': row['end_time']?.toString(),
      'duration': DatabaseValueUtils.asInt(row['duration'], fallback: 60),
      'topic': row['topic'] as String?,
      'status': row['status'] as String?,
    });
  }
}
