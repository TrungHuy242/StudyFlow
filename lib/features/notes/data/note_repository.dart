import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_service.dart';
import 'note_model.dart';

class NoteRepository {
  NoteRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<NoteModel>> getNotes() async {
    final Database database = await _databaseService.database;
    final List<Map<String, Object?>> result = await database.rawQuery('''
      SELECT notes.*, subjects.name as subject_name
      FROM notes
      LEFT JOIN subjects ON subjects.id = notes.subject_id
      ORDER BY notes.updated_at DESC
    ''');
    return result.map(NoteModel.fromMap).toList();
  }

  Future<NoteModel?> getNoteById(int id) async {
    final List<NoteModel> notes = await getNotes();
    for (final NoteModel note in notes) {
      if (note.id == id) {
        return note;
      }
    }
    return null;
  }

  Future<void> saveNote(NoteModel note) async {
    final Database database = await _databaseService.database;
    if (note.id == null) {
      await database.insert('notes', note.toMap()..remove('id'));
      return;
    }

    await database.update(
      'notes',
      note.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[note.id],
    );
  }

  Future<void> deleteNote(int id) async {
    final Database database = await _databaseService.database;
    await database.delete(
      'notes',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
