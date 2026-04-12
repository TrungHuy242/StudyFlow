import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_service.dart';
import 'study_plan_model.dart';

class StudyPlanRepository {
  StudyPlanRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<StudyPlanModel>> getPlans() async {
    final Database database = await _databaseService.database;
    final List<Map<String, Object?>> result = await database.rawQuery('''
      SELECT study_plans.*, subjects.name as subject_name, subjects.color as subject_color
      FROM study_plans
      LEFT JOIN subjects ON subjects.id = study_plans.subject_id
      ORDER BY study_plans.plan_date ASC, study_plans.start_time ASC
    ''');
    return result.map(StudyPlanModel.fromMap).toList();
  }

  Future<StudyPlanModel?> getPlanById(int id) async {
    final List<StudyPlanModel> plans = await getPlans();
    for (final StudyPlanModel plan in plans) {
      if (plan.id == id) {
        return plan;
      }
    }
    return null;
  }

  Future<void> savePlan(StudyPlanModel plan) async {
    final Database database = await _databaseService.database;
    if (plan.id == null) {
      await database.insert('study_plans', plan.toMap()..remove('id'));
      return;
    }

    await database.update(
      'study_plans',
      plan.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[plan.id],
    );
  }

  Future<void> deletePlan(int id) async {
    final Database database = await _databaseService.database;
    await database.delete(
      'study_plans',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
