import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
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
  late final TextEditingController _searchController;
  late Future<_NotesPageData> _future;
  bool _initialized = false;
  String _searchQuery = '';

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
    _searchController = TextEditingController();
    _future = _loadData();
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _searchController.dispose();
    }
    super.dispose();
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
    final NoteModel? result = await Navigator.of(context).push<NoteModel>(
      MaterialPageRoute<NoteModel>(
        builder: (BuildContext context) => NoteEditorSheet(
          initialValue: note,
          subjects: data.subjects,
        ),
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
      title: 'X\u00f3a ghi ch\u00fa?',
      message:
          '"${note.title}" s\u1ebd b\u1ecb x\u00f3a kh\u1ecfi danh s\u00e1ch ghi ch\u00fa.',
      confirmLabel: 'X\u00f3a',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await _noteRepository.deleteNote(id);
    _refreshNotifier.markDirty();
    await _refresh();
  }

  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return notes;
    }
    return notes.where((NoteModel note) {
      final String haystack = <String>[
        note.title,
        note.content,
        note.subjectName ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/calendar');
        break;
      case 2:
        context.go('/deadlines');
        break;
      case 3:
        context.go('/analytics');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: StudyFlowBottomNavBar(
        currentIndex: 0,
        onTap: _handleBottomNavTap,
      ),
      body: FutureBuilder<_NotesPageData>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<_NotesPageData> snapshot,
        ) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState(
                message: '\u0110ang t\u1ea3i ghi ch\u00fa...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Kh\u00f4ng th\u1ec3 t\u1ea3i ghi ch\u00fa',
              message:
                  'H\u00e3y th\u1eed l\u00e0m m\u1edbi danh s\u00e1ch ghi ch\u00fa.',
              onAction: _refresh,
            );
          }

          final _NotesPageData data = snapshot.data ??
              const _NotesPageData(
                notes: <NoteModel>[],
                subjects: <SubjectModel>[],
              );
          final List<NoteModel> visibleNotes = _filterNotes(data.notes);

          return SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Ghi ch\u00fa',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                      ),
                      StudyFlowCircleIconButton(
                        icon: Icons.add_rounded,
                        backgroundColor: StudyFlowPalette.blue,
                        foregroundColor: Colors.white,
                        size: 44,
                        onTap: () => _openEditor(data),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _NotesSearchBar(
                    controller: _searchController,
                    onChanged: (String value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildBody(data, visibleNotes),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(_NotesPageData data, List<NoteModel> visibleNotes) {
    if (data.notes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: <Widget>[
          const SizedBox(height: 90),
          _NotesEmptyState(
            onCreate: () => _openEditor(data),
          ),
        ],
      );
    }

    if (visibleNotes.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: const <Widget>[
          SizedBox(height: 90),
          _NotesEmptyMessage(
            title: 'Kh\u00f4ng t\u00ecm th\u1ea5y ghi ch\u00fa',
            subtitle:
                'Th\u1eed \u0111\u1ed5i t\u1eeb kh\u00f3a t\u00ecm ki\u1ebfm \u0111\u1ec3 xem c\u00e1c ghi ch\u00fa ph\u00f9 h\u1ee3p h\u01a1n.',
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: visibleNotes.length,
      itemBuilder: (BuildContext context, int index) {
        final NoteModel note = visibleNotes[index];
        return _NoteGridCard(
          note: note,
          onTap: () => _openDetail(data, note),
          onDelete: () => _deleteNote(note),
        );
      },
    );
  }
}

class _NotesSearchBar extends StatelessWidget {
  const _NotesSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: StudyFlowPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'T\u00ecm ki\u1ebfm ghi ch\u00fa...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
              ),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteGridCard extends StatelessWidget {
  const _NoteGridCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color accent = note.displayColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: StudyFlowSurfaceCard(
          color: accent.withValues(alpha: 0.08),
          radius: 28,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.note_alt_outlined,
                      color: accent,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (BuildContext context) =>
                        const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('X\u00f3a ghi ch\u00fa'),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                note.subjectName ?? 'Ghi ch\u00fa chung',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                DateTimeUtils.toDbDate(note.updatedAt),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesEmptyState extends StatelessWidget {
  const _NotesEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            color: StudyFlowPalette.surfaceSoft,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.note_alt_outlined,
            color: Color(0xFF94A3B8),
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ch\u01b0a c\u00f3 ghi ch\u00fa',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'T\u1ea1o ghi ch\u00fa \u0111\u1ec3 l\u01b0u l\u1ea1i nh\u1eefng \u00fd t\u01b0\u1edfng\nv\u00e0 ki\u1ebfn th\u1ee9c quan tr\u1ecdng',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 28),
        StudyFlowGradientButton(
          label: 'T\u1ea1o ghi ch\u00fa \u0111\u1ea7u ti\u00ean',
          onTap: onCreate,
          height: 54,
        ),
      ],
    );
  }
}

class _NotesEmptyMessage extends StatelessWidget {
  const _NotesEmptyMessage({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return StudyFlowSurfaceCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: StudyFlowPalette.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
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
