import '../../../core/database/database_service.dart';
import '../../../core/data/user_scope.dart';
import '../../../core/utils/database_value_utils.dart';
import 'note_model.dart';

class NoteRepository {
  NoteRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<NoteModel>> getNotes() async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final List<dynamic> result = await _databaseService.client
        .from('notes')
        .select('id, subject_id, title, content, color, created_at, updated_at, subjects(name)')
        .gte('id', minId)
        .lt('id', maxId)
        .order('updated_at', ascending: false);
    return result
        .map((dynamic item) => _fromRow(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<NoteModel?> getNoteById(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final dynamic result = await _databaseService.client
        .from('notes')
        .select('id, subject_id, title, content, color, created_at, updated_at, subjects(name)')
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id)
        .maybeSingle();
    if (result == null) {
      return null;
    }
    return _fromRow(Map<String, dynamic>.from(result as Map));
  }

  Future<void> saveNote(NoteModel note) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final Map<String, Object?> payload = <String, Object?>{
      'subject_id': note.subjectId,
      'title': note.title,
      'content': note.content,
      'color': note.color,
      'created_at': note.createdAt.toUtc().toIso8601String(),
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };
    if (note.id == null) {
      await _databaseService.client.from('notes').insert(<String, Object?>{
        'id': UserScope.generateId(userId),
        ...payload,
      });
      return;
    }

    await _databaseService.client
        .from('notes')
        .update(payload)
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', note.id!);
  }

  Future<void> deleteNote(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    await _databaseService.client
        .from('notes')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id);
  }

  NoteModel _fromRow(Map<String, dynamic> row) {
    final Map<String, dynamic>? subject =
        row['subjects'] is Map ? Map<String, dynamic>.from(row['subjects'] as Map) : null;
    return NoteModel.fromMap(<String, Object?>{
      'id': DatabaseValueUtils.asNullableInt(row['id']),
      'subject_id': DatabaseValueUtils.asNullableInt(row['subject_id']),
      'subject_name': subject?['name'] as String?,
      'title': row['title'] as String?,
      'content': row['content'] as String?,
      'color': row['color'] as String?,
      'created_at': row['created_at']?.toString(),
      'updated_at': row['updated_at']?.toString(),
    });
  }
}
