import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../deadlines/data/deadline_model.dart';
import '../../deadlines/data/deadline_repository.dart';
import '../data/subject_model.dart';
import '../data/subject_repository.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  late final SubjectRepository _subjectRepository;
  late final DeadlineRepository _deadlineRepository;
  late Future<_SubjectsPageData> _future;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final DatabaseService databaseService = context.read<DatabaseService>();
    _subjectRepository = SubjectRepository(databaseService);
    _deadlineRepository = DeadlineRepository(databaseService);
    _future = _loadData();
    _initialized = true;
  }

  Future<_SubjectsPageData> _loadData() async {
    final List<SubjectModel> subjects = await _subjectRepository.getSubjects();
    final List<DeadlineModel> deadlines =
        await _deadlineRepository.getDeadlines();
    return _SubjectsPageData(subjects: subjects, deadlines: deadlines);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<void> _deleteSubject(SubjectModel subject) async {
    final int? id = subject.id;
    if (id == null) {
      return;
    }

    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete subject?',
      message: '"${subject.name}" will be removed from this device.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    await _subjectRepository.deleteSubject(id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<_SubjectsPageData>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<_SubjectsPageData> snapshot,
        ) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState(message: 'Loading subjects...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load subjects',
              message: 'Try refreshing the subject list.',
              onAction: _refresh,
            );
          }

          final List<SubjectModel> subjects =
              snapshot.data?.subjects ?? <SubjectModel>[];
          final List<DeadlineModel> deadlines =
              snapshot.data?.deadlines ?? <DeadlineModel>[];
          final List<SubjectModel> filtered =
              subjects.where((SubjectModel subject) {
            final String haystack =
                '${subject.name} ${subject.code}'.toLowerCase();
            return haystack.contains(_query.toLowerCase());
          }).toList();

          final Map<int, List<DeadlineModel>> grouped =
              <int, List<DeadlineModel>>{};
          for (final DeadlineModel item in deadlines) {
            final int? subjectId = item.subjectId;
            if (subjectId == null) {
              continue;
            }
            grouped.putIfAbsent(subjectId, () => <DeadlineModel>[]).add(item);
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      StudyFlowCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.go('/home'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Subjects',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      StudyFlowCircleIconButton(
                        icon: Icons.add_rounded,
                        backgroundColor: StudyFlowPalette.blue,
                        foregroundColor: Colors.white,
                        onTap: () async {
                          await context.push('/subjects/add');
                          if (!mounted) return;
                          await _refresh();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  StudyFlowInput(
                    controller: _searchController,
                    hintText: 'Search subjects...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (String value) {
                      setState(() {
                        _query = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: filtered.isEmpty
                        ? AppEmptyState(
                            title: subjects.isEmpty
                                ? 'No subjects yet'
                                : 'No matching subjects',
                            message: subjects.isEmpty
                                ? 'Add your first subject to start organizing classes and deadlines.'
                                : 'Try a different keyword or clear the search.',
                            actionLabel:
                                subjects.isEmpty ? 'Add subject' : null,
                            onAction: subjects.isEmpty
                                ? () async {
                                    await context.push('/subjects/add');
                                    await _refresh();
                                  }
                                : null,
                            icon: Icons.menu_book_rounded,
                          )
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (BuildContext context, int index) {
                                final SubjectModel subject = filtered[index];
                                final List<DeadlineModel> subjectDeadlines =
                                    grouped[subject.id] ?? <DeadlineModel>[];
                                final int progress = subjectDeadlines.isEmpty
                                    ? 0
                                    : subjectDeadlines.fold<int>(
                                          0,
                                          (int sum, DeadlineModel d) =>
                                              sum + d.progress,
                                        ) ~/
                                        subjectDeadlines.length;
                                return InkWell(
                                  onTap: () async {
                                    await context
                                        .push('/subjects/${subject.id}');
                                    await _refresh();
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: StudyFlowSurfaceCard(
                                    child: Column(
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: subject.displayColor,
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(subject.name),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${subject.code.isEmpty ? 'No code' : subject.code} • ${subject.credits} credits',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: <Widget>[
                                                      const Icon(
                                                        Icons
                                                            .event_available_rounded,
                                                        size: 14,
                                                        color: StudyFlowPalette
                                                            .textMuted,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        subject.room.isEmpty
                                                            ? 'Room not set'
                                                            : subject.room,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              onSelected: (String value) async {
                                                switch (value) {
                                                  case 'edit':
                                                    await context.push(
                                                      '/subjects/${subject.id}/edit',
                                                    );
                                                    break;
                                                  case 'delete':
                                                    await _deleteSubject(
                                                      subject,
                                                    );
                                                    break;
                                                }
                                                if (!mounted) {
                                                  return;
                                                }
                                                await _refresh();
                                              },
                                              itemBuilder:
                                                  (BuildContext context) =>
                                                      const <PopupMenuEntry<
                                                          String>>[
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
                                        const SizedBox(height: 14),
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              'Study progress',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            const Spacer(),
                                            Text(
                                              subjectDeadlines.isEmpty
                                                  ? 'No deadlines yet'
                                                  : '$progress%',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (subjectDeadlines.isNotEmpty)
                                          StudyFlowProgressBar(
                                            value: progress / 100,
                                            color: subject.displayColor,
                                            height: 6,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubjectsPageData {
  const _SubjectsPageData({
    required this.subjects,
    required this.deadlines,
  });

  final List<SubjectModel> subjects;
  final List<DeadlineModel> deadlines;
}
