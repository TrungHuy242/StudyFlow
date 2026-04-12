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
import '../data/study_plan_model.dart';
import '../data/study_plan_repository.dart';
import 'study_plan_detail_page.dart';
import 'study_plan_editor_page.dart';

class StudyPlanPage extends StatefulWidget {
  const StudyPlanPage({super.key});

  @override
  State<StudyPlanPage> createState() => _StudyPlanPageState();
}

enum _PlanView { list, week }

class _StudyPlanPageState extends State<StudyPlanPage> {
  late final StudyPlanRepository _planRepository;
  late final SubjectRepository _subjectRepository;
  late final AppRefreshNotifier _refreshNotifier;
  late Future<_StudyPlanPageData> _future;
  bool _initialized = false;
  _PlanView _view = _PlanView.list;
  late DateTime _selectedDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final DatabaseService databaseService = context.read<DatabaseService>();
    _planRepository = StudyPlanRepository(databaseService);
    _subjectRepository = SubjectRepository(databaseService);
    _refreshNotifier = context.read<AppRefreshNotifier>();
    _selectedDate = DateTime.now();
    _future = _loadData();
    _initialized = true;
  }

  Future<_StudyPlanPageData> _loadData() async {
    final List<StudyPlanModel> plans = await _planRepository.getPlans();
    final List<SubjectModel> subjects = await _subjectRepository.getSubjects();
    return _StudyPlanPageData(plans: plans, subjects: subjects);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<void> _openEditor(_StudyPlanPageData data, [StudyPlanModel? plan]) async {
    final StudyPlanModel? result = await Navigator.of(context).push<StudyPlanModel>(
      MaterialPageRoute<StudyPlanModel>(
        builder: (BuildContext context) => StudyPlanEditorPage(
          subjects: data.subjects,
          initialValue: plan,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    await _planRepository.savePlan(result);
    _refreshNotifier.markDirty();
    await _refresh();
  }

  Future<void> _openDetail(_StudyPlanPageData data, StudyPlanModel plan) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => StudyPlanDetailPage(
          plan: plan,
          repository: _planRepository,
          subjects: data.subjects,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _deletePlan(StudyPlanModel plan) async {
    final int? id = plan.id;
    if (id == null) {
      return;
    }
    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete study plan?',
      message: '"${plan.title}" will be removed from your schedule.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await _planRepository.deletePlan(id);
    _refreshNotifier.markDirty();
    await _refresh();
  }

  List<DateTime> get _weekDays {
    final DateTime start = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return List<DateTime>.generate(
      7,
      (int index) => DateTime(
        start.year,
        start.month,
        start.day + index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyFlowPalette.background,
      floatingActionButton: FutureBuilder<_StudyPlanPageData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_StudyPlanPageData> snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            backgroundColor: StudyFlowPalette.blue,
            onPressed: () => _openEditor(snapshot.data!),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          );
        },
      ),
      body: FutureBuilder<_StudyPlanPageData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_StudyPlanPageData> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState(message: 'Loading study plans...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load study plans',
              message: 'Try refreshing the study plan screen.',
              onAction: _refresh,
            );
          }

          final _StudyPlanPageData data = snapshot.data ??
              const _StudyPlanPageData(
                plans: <StudyPlanModel>[],
                subjects: <SubjectModel>[],
              );

          if (data.plans.isEmpty) {
            return _StudyPlanEmptyState(onAdd: () => _openEditor(data));
          }

          final List<StudyPlanModel> upcoming = data.plans
              .where((StudyPlanModel plan) => plan.status != 'Done')
              .toList()
            ..sort((StudyPlanModel a, StudyPlanModel b) => a.planDate.compareTo(b.planDate));
          final List<StudyPlanModel> completed = data.plans
              .where((StudyPlanModel plan) => plan.status == 'Done')
              .toList()
            ..sort((StudyPlanModel a, StudyPlanModel b) => b.planDate.compareTo(a.planDate));
          final List<StudyPlanModel> selectedDayPlans = data.plans.where((StudyPlanModel plan) {
            final DateTime value = plan.planDate;
            return value.year == _selectedDate.year &&
                value.month == _selectedDate.month &&
                value.day == _selectedDate.day;
          }).toList()
            ..sort((StudyPlanModel a, StudyPlanModel b) => a.timeLabel.compareTo(b.timeLabel));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: _view == _PlanView.list
                ? _PlanListView(
                    upcoming: upcoming,
                    completed: completed,
                    onAdd: () => _openEditor(data),
                    onChangeView: (_PlanView value) {
                      setState(() {
                        _view = value;
                      });
                    },
                    onTapItem: (StudyPlanModel value) => _openDetail(data, value),
                    onDeleteItem: _deletePlan,
                  )
                : _PlanWeekView(
                    weekDays: _weekDays,
                    selectedDate: _selectedDate,
                    items: selectedDayPlans,
                    onAdd: () => _openEditor(data),
                    onChangeView: (_PlanView value) {
                      setState(() {
                        _view = value;
                      });
                    },
                    onSelectDate: (DateTime value) {
                      setState(() {
                        _selectedDate = value;
                      });
                    },
                    onTapItem: (StudyPlanModel value) => _openDetail(data, value),
                    onDeleteItem: _deletePlan,
                  ),
          );
        },
      ),
    );
  }
}

class _StudyPlanPageData {
  const _StudyPlanPageData({
    required this.plans,
    required this.subjects,
  });

  final List<StudyPlanModel> plans;
  final List<SubjectModel> subjects;
}

class _StudyPlanEmptyState extends StatelessWidget {
  const _StudyPlanEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Study Plan', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: AppEmptyState(
                  title: 'No study plans yet',
                  message:
                      'Add your first study block to keep daily review sessions organized.',
                  actionLabel: 'Create plan',
                  onAction: onAdd,
                  icon: Icons.event_note_rounded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanListView extends StatelessWidget {
  const _PlanListView({
    required this.upcoming,
    required this.completed,
    required this.onAdd,
    required this.onChangeView,
    required this.onTapItem,
    required this.onDeleteItem,
  });

  final List<StudyPlanModel> upcoming;
  final List<StudyPlanModel> completed;
  final VoidCallback onAdd;
  final ValueChanged<_PlanView> onChangeView;
  final ValueChanged<StudyPlanModel> onTapItem;
  final ValueChanged<StudyPlanModel> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Study Plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton(
                onPressed: onAdd,
                child: const Text('Add plan'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PlanViewTabs(
            currentView: _PlanView.list,
            onChangeView: onChangeView,
          ),
          const SizedBox(height: 18),
          Text('Upcoming', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            const AppEmptyState(
              title: 'No upcoming study blocks',
              message: 'Your active study sessions will appear here.',
              icon: Icons.schedule_rounded,
            )
          else
            ...upcoming.map((StudyPlanModel plan) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StudyPlanCard(
                  plan: plan,
                  onTap: () => onTapItem(plan),
                  onDelete: () => onDeleteItem(plan),
                ),
              );
            }),
          const SizedBox(height: 18),
          Text('Completed', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (completed.isEmpty)
            const AppEmptyState(
              title: 'No completed plans yet',
              message: 'Completed study blocks will appear here.',
              icon: Icons.task_alt_rounded,
            )
          else
            ...completed.map((StudyPlanModel plan) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StudyPlanCard(
                  plan: plan,
                  onTap: () => onTapItem(plan),
                  onDelete: () => onDeleteItem(plan),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PlanWeekView extends StatelessWidget {
  const _PlanWeekView({
    required this.weekDays,
    required this.selectedDate,
    required this.items,
    required this.onAdd,
    required this.onChangeView,
    required this.onSelectDate,
    required this.onTapItem,
    required this.onDeleteItem,
  });

  final List<DateTime> weekDays;
  final DateTime selectedDate;
  final List<StudyPlanModel> items;
  final VoidCallback onAdd;
  final ValueChanged<_PlanView> onChangeView;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<StudyPlanModel> onTapItem;
  final ValueChanged<StudyPlanModel> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Study Plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton(
                onPressed: onAdd,
                child: const Text('Add plan'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PlanViewTabs(
            currentView: _PlanView.week,
            onChangeView: onChangeView,
          ),
          const SizedBox(height: 18),
          Row(
            children: weekDays.map((DateTime date) {
              final bool selected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => onSelectDate(date),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? StudyFlowPalette.blue
                            : StudyFlowPalette.surfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(
                            _weekLabel(date.weekday),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : StudyFlowPalette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : StudyFlowPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text(
            'Plans for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const AppEmptyState(
              title: 'No study blocks on this day',
              message: 'Pick another date or add a plan for this day.',
              icon: Icons.event_busy_rounded,
            )
          else
            ...items.map((StudyPlanModel plan) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StudyPlanCard(
                  plan: plan,
                  onTap: () => onTapItem(plan),
                  onDelete: () => onDeleteItem(plan),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _weekLabel(int weekday) {
    const List<String> labels = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return labels[weekday - 1];
  }
}

class _PlanViewTabs extends StatelessWidget {
  const _PlanViewTabs({
    required this.currentView,
    required this.onChangeView,
  });

  final _PlanView currentView;
  final ValueChanged<_PlanView> onChangeView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StudyFlowPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          _PlanViewTab(
            label: 'List',
            selected: currentView == _PlanView.list,
            onTap: () => onChangeView(_PlanView.list),
          ),
          _PlanViewTab(
            label: 'Week',
            selected: currentView == _PlanView.week,
            onTap: () => onChangeView(_PlanView.week),
          ),
        ],
      ),
    );
  }
}

class _PlanViewTab extends StatelessWidget {
  const _PlanViewTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? StudyFlowPalette.textPrimary
                  : StudyFlowPalette.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyPlanCard extends StatelessWidget {
  const _StudyPlanCard({
    required this.plan,
    required this.onTap,
    required this.onDelete,
  });

  final StudyPlanModel plan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: StudyFlowSurfaceCard(
        child: Row(
          children: <Widget>[
            Container(
              width: 6,
              height: 72,
              decoration: BoxDecoration(
                color: plan.status == 'Done'
                    ? StudyFlowPalette.green
                    : StudyFlowPalette.blue,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    plan.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.subjectName ?? 'General',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${plan.dateLabel} • ${plan.timeLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (plan.topic.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      plan.topic,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: StudyFlowPalette.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
