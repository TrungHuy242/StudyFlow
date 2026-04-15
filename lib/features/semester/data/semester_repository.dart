import '../../../core/database/database_service.dart';
import '../../../core/data/user_scope.dart';
import '../../../core/utils/database_value_utils.dart';
import 'semester_model.dart';

class SemesterRepository {
  SemesterRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<SemesterModel>> getSemesters() async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final List<dynamic> result = await _databaseService.client
        .from('semesters')
        .select('id, name, start_date, end_date, is_active')
        .gte('id', minId)
        .lt('id', maxId)
        .order('start_date', ascending: false);
    return result
        .map((dynamic item) => SemesterModel.fromMap(
              Map<String, Object?>.from(item as Map),
            ))
        .toList();
  }

  Future<SemesterModel?> getActiveSemester() async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final dynamic result = await _databaseService.client
        .from('semesters')
        .select('id, name, start_date, end_date, is_active')
        .gte('id', minId)
        .lt('id', maxId)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    if (result == null) {
      return null;
    }
    return SemesterModel.fromMap(Map<String, Object?>.from(result as Map));
  }

  Future<void> saveSemester(SemesterModel semester) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    if (semester.isActive) {
      await _databaseService.client
          .from('semesters')
          .update(<String, Object?>{'is_active': false})
          .gte('id', minId)
          .lt('id', maxId)
          .neq('id', semester.id ?? -1);
    }

    final Map<String, Object?> payload = <String, Object?>{
      'name': semester.name,
      'start_date': semester.toMap()['start_date'],
      'end_date': semester.toMap()['end_date'],
      'is_active': semester.isActive,
    };

    if (semester.id == null) {
      await _databaseService.client.from('semesters').insert(<String, Object?>{
        'id': UserScope.generateId(userId),
        ...payload,
      });
    } else {
      await _databaseService.client
          .from('semesters')
          .update(payload)
          .gte('id', minId)
          .lt('id', maxId)
          .eq('id', semester.id!);
    }

    final List<SemesterModel> semesters = await getSemesters();
    final bool hasActive = semesters.any((SemesterModel item) => item.isActive);
    if (semesters.isNotEmpty && !hasActive) {
      final SemesterModel latest = semesters.first;
      await setActiveSemester(latest.id!);
    }
  }

  Future<void> setActiveSemester(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    await _databaseService.client
        .from('semesters')
        .update(<String, Object?>{'is_active': false})
        .gte('id', minId)
        .lt('id', maxId)
        .neq('id', -1);
    await _databaseService.client
        .from('semesters')
        .update(<String, Object?>{'is_active': true})
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id);
  }

  Future<void> deleteSemester(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    await _databaseService.client
        .from('semesters')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id);

    final List<SemesterModel> semesters = await getSemesters();
    final bool hasActive = semesters.any((SemesterModel item) => item.isActive);
    if (semesters.isNotEmpty && !hasActive) {
      final SemesterModel latest = semesters.first;
      final int? latestId = DatabaseValueUtils.asNullableInt(latest.id);
      if (latestId != null) {
        await setActiveSemester(latestId);
      }
    }
  }
}
