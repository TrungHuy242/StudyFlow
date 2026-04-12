import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_section_card.dart';
import '../../subjects/data/subject_model.dart';
import '../data/note_model.dart';
import '../data/note_repository.dart';
import 'widgets/note_editor_sheet.dart';

class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({
    super.key,
    required this.note,
    required this.repository,
    required this.subjects,
  });

  final NoteModel note;
  final NoteRepository repository;
  final List<SubjectModel> subjects;

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late NoteModel _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  Future<void> _editNote() async {
    final AppRefreshNotifier refreshNotifier = context.read<AppRefreshNotifier>();
    final NoteModel? updated = await showModalBottomSheet<NoteModel>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return NoteEditorSheet(
          initialValue: _note,
          subjects: widget.subjects,
        );
      },
    );
    if (updated == null) {
      return;
    }
    await widget.repository.saveNote(updated);
    if (!mounted) {
      return;
    }
    refreshNotifier.markDirty();
    final NoteModel? refreshed = await widget.repository.getNoteById(updated.id!);
    if (refreshed == null || !mounted) {
      return;
    }
    setState(() {
      _note = refreshed;
    });
  }

  Future<void> _deleteNote() async {
    final int? id = _note.id;
    if (id == null) {
      return;
    }
    final AppRefreshNotifier refreshNotifier = context.read<AppRefreshNotifier>();
    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete note?',
      message: '"${_note.title}" will be removed from your notes.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await widget.repository.deleteNote(id);
    if (!mounted) {
      return;
    }
    refreshNotifier.markDirty();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_note.title),
        actions: <Widget>[
          IconButton(
            onPressed: _editNote,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _deleteNote,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        children: <Widget>[
          AppSectionCard(
            title: _note.subjectName ?? 'General note',
            subtitle: 'Updated ${_note.updatedLabel}',
            child: Text(
              _note.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
