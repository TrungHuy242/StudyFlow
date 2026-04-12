import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../subjects/data/subject_model.dart';
import '../../subjects/data/subject_repository.dart';
import '../data/note_model.dart';
import '../data/note_repository.dart';
import 'note_detail_page.dart';
import 'widgets/note_editor_sheet.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late final NoteRepository _noteRepository;
  late final SubjectRepository _subjectRepository;
  late final AppRefreshNotifier _refreshNotifier;
  late Future<_NotesPageData> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final DatabaseService databaseService = context.read<DatabaseService>();
    _noteRepository = NoteRepository(databaseService);
    _subjectRepository = SubjectRepository(databaseService);
    _refreshNotifier = context.read<AppRefreshNotifier>();
    _future = _loadData();
    _initialized = true;
  }

  Future<_NotesPageData> _loadData() async {
    final List<NoteModel> notes = await _noteRepository.getNotes();
    final List<SubjectModel> subjects = await _subjectRepository.getSubjects();
    return _NotesPageData(notes: notes, subjects: subjects);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<void> _openEditor(_NotesPageData data, [NoteModel? note]) async {
    final NoteModel? result = await showModalBottomSheet<NoteModel>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => NoteEditorSheet(
        initialValue: note,
        subjects: data.subjects,
      ),
    );
    if (result == null) {
      return;
    }
    await _noteRepository.saveNote(result);
    _refreshNotifier.markDirty();
    await _refresh();
  }

  Future<void> _openDetail(_NotesPageData data, NoteModel note) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => NoteDetailPage(
          note: note,
          repository: _noteRepository,
          subjects: data.subjects,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _deleteNote(NoteModel note) async {
    final int? id = note.id;
    if (id == null) {
      return;
    }
    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete note?',
      message: '"${note.title}" will be removed from your notes.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await _noteRepository.deleteNote(id);
    _refreshNotifier.markDirty();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<_NotesPageData>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<_NotesPageData> snapshot,
        ) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState(message: 'Loading notes...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load notes',
              message: 'Try refreshing the notes list.',
              onAction: _refresh,
            );
          }

          final _NotesPageData data = snapshot.data ??
              const _NotesPageData(
                notes: <NoteModel>[],
                subjects: <SubjectModel>[],
              );

          return SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Notes',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      StudyFlowCircleIconButton(
                        icon: Icons.add_rounded,
                        backgroundColor: StudyFlowPalette.blue,
                        foregroundColor: Colors.white,
                        onTap: () => _openEditor(data),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: <Widget>[
                        if (data.notes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: AppEmptyState(
                              title: 'No notes yet',
                              message:
                                  'Add your first note to keep quick study references handy.',
                              actionLabel: 'Add note',
                              onAction: () => _openEditor(data),
                              icon: Icons.note_outlined,
                            ),
                          )
                        else
                          ...data.notes.map((NoteModel note) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: InkWell(
                                onTap: () => _openDetail(data, note),
                                borderRadius: BorderRadius.circular(20),
                                child: StudyFlowSurfaceCard(
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: note.displayColor
                                              .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          Icons.note_outlined,
                                          color: note.displayColor,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              note.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${note.subjectName ?? 'General'} | ${note.updatedLabel}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (String value) async {
                                          switch (value) {
                                            case 'edit':
                                              await _openEditor(data, note);
                                              break;
                                            case 'delete':
                                              await _deleteNote(note);
                                              break;
                                          }
                                        },
                                        itemBuilder:
                                            (BuildContext context) =>
                                                const <PopupMenuEntry<String>>[
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotesPageData {
  const _NotesPageData({
    required this.notes,
    required this.subjects,
  });

  final List<NoteModel> notes;
  final List<SubjectModel> subjects;
}
