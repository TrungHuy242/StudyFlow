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

  Future<void> _openEditor(_StudyPlanPageData data,
      [StudyPlanModel? plan]) async {
    final StudyPlanModel? result =
        await Navigator.of(context).push<StudyPlanModel>(
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
      title: 'Xóa kế hoạch ôn tập?',
      message: '"${plan.title}" sẽ bị xóa khỏi danh sách kế hoạch ôn tập.',
      confirmLabel: 'Xóa',
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
      body: FutureBuilder<_StudyPlanPageData>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<_StudyPlanPageData> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState(
                message: 'Đang tải kế hoạch ôn tập...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Không thể tải kế hoạch ôn tập',
              message: 'Hãy thử làm mới màn hình kế hoạch ôn tập.',
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
            ..sort(
              (StudyPlanModel a, StudyPlanModel b) =>
                  a.planDate.compareTo(b.planDate),
            );
          final List<StudyPlanModel> completed = data.plans
              .where((StudyPlanModel plan) => plan.status == 'Done')
              .toList()
            ..sort(
              (StudyPlanModel a, StudyPlanModel b) =>
                  b.planDate.compareTo(a.planDate),
            );
          final List<StudyPlanModel> selectedDayPlans =
              data.plans.where((StudyPlanModel plan) {
            final DateTime value = plan.planDate;
            return value.year == _selectedDate.year &&
                value.month == _selectedDate.month &&
                value.day == _selectedDate.day;
          }).toList()
                ..sort(
                  (StudyPlanModel a, StudyPlanModel b) =>
                      a.timeLabel.compareTo(b.timeLabel),
                );

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
                    onTapItem: (StudyPlanModel value) =>
                        _openDetail(data, value),
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
                    onTapItem: (StudyPlanModel value) =>
                        _openDetail(data, value),
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Kế hoạch ôn tập',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 90),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        color: StudyFlowPalette.surfaceSoft,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.auto_stories_outlined,
                        color: Color(0xFF94A3B8),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chưa có kế hoạch',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tạo kế hoạch ôn tập để theo dõi và đạt\nđược mục tiêu học tập',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF64748B),
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 28),
                    StudyFlowGradientButton(
                      label: 'Tạo kế hoạch đầu tiên',
                      onTap: onAdd,
                      height: 54,
                    ),
                  ],
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Kế hoạch ôn tập',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              StudyFlowCircleIconButton(
                icon: Icons.add_rounded,
                size: 44,
                backgroundColor: StudyFlowPalette.blue,
                foregroundColor: Colors.white,
                onTap: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PlanViewTabs(
            currentView: _PlanView.list,
            onChangeView: onChangeView,
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _PlanStatCard(
                  value: '${upcoming.length}',
                  label: 'Kế hoạch sắp tới',
                  color: StudyFlowPalette.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlanStatCard(
                  value: '${completed.length}',
                  label: 'Đã hoàn thành',
                  color: StudyFlowPalette.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Sắp tới',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            const _CompactPlanEmpty(title: 'Không có kế hoạch sắp tới')
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
          Text(
            'Đã hoàn thành',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (completed.isEmpty)
            const _CompactPlanEmpty(title: 'Chưa có kế hoạch hoàn thành')
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

  int _weekNumber(DateTime date) {
    final DateTime target = DateTime(date.year, date.month, date.day);
    final DateTime thursday = target.add(Duration(days: 4 - target.weekday));
    final DateTime firstThursday = DateTime(thursday.year, 1, 4);
    return ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
  }

  String _weekLabel(int weekday) {
    const List<String> labels = <String>[
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'CN'
    ];
    return labels[weekday - 1];
  }

  String _selectedDateLabel() {
    const List<String> labels = <String>[
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    return '${labels[selectedDate.weekday - 1]}, ngày ${selectedDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Kế hoạch tuần',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              StudyFlowCircleIconButton(
                icon: Icons.add_rounded,
                size: 44,
                backgroundColor: StudyFlowPalette.blue,
                foregroundColor: Colors.white,
                onTap: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PlanViewTabs(
            currentView: _PlanView.week,
            onChangeView: onChangeView,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Tuần ${_weekNumber(selectedDate)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: weekDays.map((DateTime date) {
              final bool selected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => onSelectDate(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? StudyFlowPalette.blue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(
                            _weekLabel(date.weekday),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF475569),
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
          const SizedBox(height: 24),
          Text(
            _selectedDateLabel(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: StudyFlowPalette.surfaceSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Text(
                'Không có kế hoạch',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontSize: 16,
                    ),
              ),
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
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StudyFlowPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          _PlanViewTab(
            label: 'Danh sách',
            selected: currentView == _PlanView.list,
            onTap: () => onChangeView(_PlanView.list),
          ),
          _PlanViewTab(
            label: 'Tuần',
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
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanStatCard extends StatelessWidget {
  const _PlanStatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompactPlanEmpty extends StatelessWidget {
  const _CompactPlanEmpty({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: StudyFlowPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF94A3B8),
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

  bool get _isDone => plan.status == 'Done';

  @override
  Widget build(BuildContext context) {
    final Color accent =
        _isDone ? StudyFlowPalette.green : StudyFlowPalette.blue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: StudyFlowPalette.border),
          boxShadow: StudyFlowPalette.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isDone ? Icons.check_rounded : Icons.auto_stories_outlined,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            plan.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: _isDone
                                      ? const Color(0xFF334155)
                                      : const Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isDone ? 'Đã hoàn thành' : 'Sắp tới',
                          style: TextStyle(
                            color: _isDone
                                ? StudyFlowPalette.green
                                : const Color(0xFF1D4ED8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.subjectName ?? 'Chung',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _isDone
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Text(
                          DateTimeUtils.toDbDate(plan.planDate),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          plan.timeLabel,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                padding: EdgeInsets.zero,
                itemBuilder: (BuildContext context) =>
                    const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Xóa kế hoạch'),
                  ),
                ],
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
