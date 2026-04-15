import '../../../core/database/database_service.dart';
import '../../../core/data/user_scope.dart';
import '../../../core/utils/database_value_utils.dart';
import 'subject_model.dart';

class SubjectRepository {
  SubjectRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<SubjectModel>> getSubjects({int? semesterId}) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    dynamic query = _databaseService.client
        .from('subjects')
        .select('id, semester_id, name, code, color, credits, teacher, room, note, semesters(name)')
        .gte('id', minId)
        .lt('id', maxId);
    if (semesterId != null) {
      query = query.eq('semester_id', semesterId);
    }

    final List<dynamic> result = await query.order('name');
    return result
        .map((dynamic item) => _fromRow(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<SubjectModel?> getSubjectById(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final dynamic result = await _databaseService.client
        .from('subjects')
        .select('id, semester_id, name, code, color, credits, teacher, room, note, semesters(name)')
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id)
        .maybeSingle();
    if (result == null) {
      return null;
    }
    return _fromRow(Map<String, dynamic>.from(result as Map));
  }

  Future<void> saveSubject(SubjectModel subject) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final Map<String, Object?> payload = _toPayload(subject);
    if (subject.id == null) {
      await _databaseService.client.from('subjects').insert(<String, Object?>{
        'id': UserScope.generateId(userId),
        ...payload,
      });
      return;
    }

    await _databaseService.client
        .from('subjects')
        .update(payload)
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', subject.id!);
  }

  Future<void> deleteSubject(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    await _databaseService.client
        .from('subjects')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id);
  }

  SubjectModel _fromRow(Map<String, dynamic> row) {
    final Map<String, dynamic>? semester =
        row['semesters'] is Map ? Map<String, dynamic>.from(row['semesters'] as Map) : null;
    return SubjectModel.fromMap(<String, Object?>{
      'id': DatabaseValueUtils.asNullableInt(row['id']),
      'semester_id': DatabaseValueUtils.asNullableInt(row['semester_id']),
      'semester_name': semester?['name'] as String?,
      'name': row['name'] as String?,
      'code': row['code'] as String?,
      'color': row['color'] as String?,
      'credits': DatabaseValueUtils.asInt(row['credits'], fallback: 3),
      'teacher': row['teacher'] as String?,
      'room': row['room'] as String?,
      'note': row['note'] as String?,
    });
  }

  Map<String, Object?> _toPayload(SubjectModel subject) {
    return <String, Object?>{
      'semester_id': subject.semesterId,
      'name': subject.name,
      'code': subject.code,
      'color': subject.color,
      'credits': subject.credits,
      'teacher': subject.teacher,
      'room': subject.room,
      'note': subject.note,
    };
  }
}
