import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_service.dart';
import 'subject_model.dart';

class SubjectRepository {
  SubjectRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<SubjectModel>> getSubjects({int? semesterId}) async {
    final Database database = await _databaseService.database;
    final StringBuffer query = StringBuffer('''
      SELECT subjects.*, semesters.name as semester_name
      FROM subjects
      LEFT JOIN semesters ON semesters.id = subjects.semester_id
    ''');
    final List<Object?> args = <Object?>[];
    if (semesterId != null) {
      query.write(' WHERE subjects.semester_id = ?');
      args.add(semesterId);
    }
    query.write(' ORDER BY subjects.name COLLATE NOCASE');

    final List<Map<String, Object?>> result = await database.rawQuery(
      query.toString(),
      args,
    );
    return result.map(SubjectModel.fromMap).toList();
  }

  Future<SubjectModel?> getSubjectById(int id) async {
    final List<SubjectModel> result = await getSubjects();
    for (final SubjectModel subject in result) {
      if (subject.id == id) {
        return subject;
      }
    }
    return null;
  }

  Future<void> saveSubject(SubjectModel subject) async {
    final Database database = await _databaseService.database;
    if (subject.id == null) {
      await database.insert('subjects', subject.toMap()..remove('id'));
      return;
    }

    await database.update(
      'subjects',
      subject.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[subject.id],
    );
  }

  Future<void> deleteSubject(int id) async {
    final Database database = await _databaseService.database;
    await database.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
