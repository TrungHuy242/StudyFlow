import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../subjects/data/subject_model.dart';
import '../../subjects/data/subject_repository.dart';
import '../data/deadline_model.dart';
import '../data/deadline_repository.dart';
import 'deadline_detail_page.dart';
import 'deadline_editor_page.dart';

class DeadlinesPage extends StatefulWidget {
  const DeadlinesPage({super.key});

  @override
  State<DeadlinesPage> createState() => _DeadlinesPageState();
}

enum _DeadlineView { today, week, overdue }

class _DeadlinesPageState extends State<DeadlinesPage> {
  late final DeadlineRepository _deadlineRepository;
  late final SubjectRepository _subjectRepository;
  late final AppRefreshNotifier _refreshNotifier;
  late Future<_DeadlinesPageData> _future;
  bool _initialized = false;
  _DeadlineView _view = _DeadlineView.today;
  late DateTime _selectedWeekDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final DatabaseService databaseService = context.read<DatabaseService>();
    _deadlineRepository = DeadlineRepository(databaseService);
    _subjectRepository = SubjectRepository(databaseService);
    _refreshNotifier = context.read<AppRefreshNotifier>();
    _selectedWeekDate = DateTime.now();
    _future = _loadData();
    _initialized = true;
  }

  Future<_DeadlinesPageData> _loadData() async {
    final List<DeadlineModel> deadlines = await _deadlineRepository.getDeadlines();
    final List<SubjectModel> subjects = await _subjectRepository.getSubjects();
    return _DeadlinesPageData(deadlines: deadlines, subjects: subjects);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<void> _openEditor(_DeadlinesPageData data, [DeadlineModel? deadline]) async {
    final DeadlineModel? result = await Navigator.of(context).push<DeadlineModel>(
      MaterialPageRoute<DeadlineModel>(
        builder: (BuildContext context) => DeadlineEditorPage(
          subjects: data.subjects,
          initialValue: deadline,
        ),
      ),
    );
    if (result == null) return;
    await _deadlineRepository.saveDeadline(result);
    _refreshNotifier.markDirty();
    await _refresh();
  }

  Future<void> _openDetail(_DeadlinesPageData data, DeadlineModel deadline) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => DeadlineDetailPage(
          deadline: deadline,
          repository: _deadlineRepository,
          subjects: data.subjects,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _deleteDeadline(DeadlineModel deadline) async {
    if (deadline.id == null) return;
    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Xóa deadline?',
      message: 'Deadline này sẽ bị xóa khỏi danh sách theo dõi.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!confirmed) return;
    await _deadlineRepository.deleteDeadline(deadline.id!);
    _refreshNotifier.markDirty();
    await _refresh();
  }

  List<DeadlineModel> _todayDeadlines(List<DeadlineModel> deadlines) {
    final DateTime today = _dayOnly(DateTime.now());
    return deadlines.where((DeadlineModel deadline) {
      return !deadline.isDone && _dayOnly(deadline.dueDate) == today;
    }).toList();
  }

  List<DeadlineModel> _weekDeadlines(List<DeadlineModel> deadlines) {
    final DateTime selected = _dayOnly(_selectedWeekDate);
    return deadlines.where((DeadlineModel deadline) {
      return !deadline.isDone && _dayOnly(deadline.dueDate) == selected;
    }).toList()
      ..sort((DeadlineModel a, DeadlineModel b) => a.dueAt.compareTo(b.dueAt));
  }

  List<DeadlineModel> _overdueDeadlines(List<DeadlineModel> deadlines) {
    return deadlines.where((DeadlineModel deadline) => deadline.isOverdue).toList()
      ..sort((DeadlineModel a, DeadlineModel b) => a.dueAt.compareTo(b.dueAt));
  }

  List<DateTime> get _weekDays {
    final DateTime today = _dayOnly(DateTime.now());
    final DateTime start = today.subtract(Duration(days: today.weekday - 1));
    return List<DateTime>.generate(7, (int index) => start.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FutureBuilder<_DeadlinesPageData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_DeadlinesPageData> snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: StudyFlowPalette.blue,
            onPressed: () => _openEditor(snapshot.data!),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          );
        },
      ),
      body: FutureBuilder<_DeadlinesPageData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_DeadlinesPageData> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final _DeadlinesPageData data = snapshot.data ??
              const _DeadlinesPageData(deadlines: <DeadlineModel>[], subjects: <SubjectModel>[]);
          if (data.deadlines.isEmpty) {
            return _DeadlineEmptyState(onAdd: () => _openEditor(data));
          }
          final List<DeadlineModel> today = _todayDeadlines(data.deadlines);
          final List<DeadlineModel> week = _weekDeadlines(data.deadlines);
          final List<DeadlineModel> overdue = _overdueDeadlines(data.deadlines);
          final Widget body = switch (_view) {
            _DeadlineView.today => _DeadlineTodayView(
                items: today,
                onModeChanged: ( _DeadlineView value) => setState(() => _view = value),
                onTapItem: (DeadlineModel value) => _openDetail(data, value),
              ),
            _DeadlineView.week => _DeadlineWeekView(
                items: week,
                selectedDate: _selectedWeekDate,
                weekDays: _weekDays,
                onSelectDate: (DateTime value) => setState(() => _selectedWeekDate = value),
                onModeChanged: ( _DeadlineView value) => setState(() => _view = value),
                onTapItem: (DeadlineModel value) => _openDetail(data, value),
                onDeleteItem: _deleteDeadline,
              ),
            _DeadlineView.overdue => _DeadlineOverdueView(
                items: overdue,
                onModeChanged: ( _DeadlineView value) => setState(() => _view = value),
                onTapItem: (DeadlineModel value) => _openDetail(data, value),
              ),
          };
          return RefreshIndicator(onRefresh: _refresh, child: body);
        },
      ),
    );
  }
}

class _DeadlinesPageData {
  const _DeadlinesPageData({required this.deadlines, required this.subjects});
  final List<DeadlineModel> deadlines;
  final List<SubjectModel> subjects;
}

class _DeadlineTodayView extends StatelessWidget {
  const _DeadlineTodayView({
    required this.items,
    required this.onModeChanged,
    required this.onTapItem,
  });

  final List<DeadlineModel> items;
  final ValueChanged<_DeadlineView> onModeChanged;
  final ValueChanged<DeadlineModel> onTapItem;

  @override
  Widget build(BuildContext context) {
    final int urgentCount = items.where((DeadlineModel item) => item.priority == 'High').length;
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Container(
          color: const Color(0xFFFF850B),
          padding: const EdgeInsets.fromLTRB(22, 52, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Deadline hôm nay',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 26,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ngày ${DateTime.now().day} tháng ${DateTime.now().month}, ${DateTime.now().year}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
              ),
              const SizedBox(height: 16),
              _ModeSwitch(selected: _DeadlineView.today, onChanged: onModeChanged),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(child: _HeroStatCard(value: '${items.length}', label: 'Cần làm')),
                  const SizedBox(width: 12),
                  Expanded(child: _HeroStatCard(value: '$urgentCount', label: 'Khẩn cấp')),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
          child: items.isEmpty
              ? const _InlineMessageCard(
                  title: 'Hôm nay không có deadline',
                  subtitle: 'Chuyển sang tuần này hoặc thêm một deadline mới.',
                )
              : Column(
                  children: items.map((DeadlineModel item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _TodayDeadlineCard(deadline: item, onTap: () => onTapItem(item)),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _DeadlineWeekView extends StatelessWidget {
  const _DeadlineWeekView({
    required this.items,
    required this.selectedDate,
    required this.weekDays,
    required this.onSelectDate,
    required this.onModeChanged,
    required this.onTapItem,
    required this.onDeleteItem,
  });

  final List<DeadlineModel> items;
  final DateTime selectedDate;
  final List<DateTime> weekDays;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<_DeadlineView> onModeChanged;
  final ValueChanged<DeadlineModel> onTapItem;
  final ValueChanged<DeadlineModel> onDeleteItem;

  @override
  Widget build(BuildContext context) {
    final DateTime start = weekDays.first;
    final DateTime end = weekDays.last;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 52, 22, 110),
      children: <Widget>[
        Text(
          'Deadline tuần này',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 6),
        Text(
          '${start.day} - ${end.day} tháng ${start.month}, ${start.year}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: StudyFlowPalette.textSecondary),
        ),
        const SizedBox(height: 16),
        _ModeSwitch(selected: _DeadlineView.week, onChanged: onModeChanged),
        const SizedBox(height: 18),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: weekDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final DateTime item = weekDays[index];
              final bool selected = _dayOnly(item) == _dayOnly(selectedDate);
              return InkWell(
                onTap: () => onSelectDate(item),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 52,
                  decoration: BoxDecoration(
                    color: selected ? StudyFlowPalette.blue : StudyFlowPalette.surfaceSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _weekdayLabel(item.weekday),
                        style: TextStyle(
                          color: selected ? Colors.white : StudyFlowPalette.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.day}',
                        style: TextStyle(
                          color: selected ? Colors.white : StudyFlowPalette.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 0.9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        if (items.isEmpty)
          const _InlineMessageCard(
            title: 'Không có deadline cho ngày này',
            subtitle: 'Chọn ngày khác trong tuần hoặc thêm deadline mới.',
          )
        else
          ...items.map((DeadlineModel item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _WeekDeadlineCard(
                deadline: item,
                onTap: () => onTapItem(item),
                onDelete: () => onDeleteItem(item),
              ),
            );
          }),
      ],
    );
  }
}

class _DeadlineOverdueView extends StatelessWidget {
  const _DeadlineOverdueView({
    required this.items,
    required this.onModeChanged,
    required this.onTapItem,
  });

  final List<DeadlineModel> items;
  final ValueChanged<_DeadlineView> onModeChanged;
  final ValueChanged<DeadlineModel> onTapItem;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        Container(
          color: const Color(0xFFF83F4D),
          padding: const EdgeInsets.fromLTRB(22, 52, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Quá hạn',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontSize: 26),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${items.length} deadline đã quá hạn',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.84)),
              ),
              const SizedBox(height: 16),
              _ModeSwitch(selected: _DeadlineView.overdue, onChanged: onModeChanged),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
          child: items.isEmpty
              ? const _InlineMessageCard(
                  title: 'Không có deadline quá hạn',
                  subtitle: 'Tiến độ hiện tại của bạn đang rất tốt.',
                )
              : Column(
                  children: <Widget>[
                    ...items.map((DeadlineModel item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _OverdueDeadlineCard(deadline: item, onTap: () => onTapItem(item)),
                      );
                    }),
                    StudyFlowSurfaceCard(
                      color: const Color(0xFFFFF7D6),
                      child: Text(
                        'Những deadline quá hạn sẽ ảnh hưởng đến điểm số và tiến độ học tập của bạn. Hãy cố gắng hoàn thành chúng sớm nhất có thể.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFFB45309),
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DeadlineEmptyState extends StatelessWidget {
  const _DeadlineEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 56, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Deadline', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26)),
            const Spacer(),
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: StudyFlowPalette.surfaceSoft, shape: BoxShape.circle),
                child: const Icon(Icons.description_outlined, color: StudyFlowPalette.textMuted, size: 42),
              ),
            ),
            const SizedBox(height: 24),
            Center(child: Text('Chưa có deadline', style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Thêm deadline để theo dõi các nhiệm vụ và bài tập quan trọng',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: StudyFlowPalette.textSecondary),
              ),
            ),
            const SizedBox(height: 26),
            StudyFlowGradientButton(label: '+ Thêm deadline đầu tiên', onTap: onAdd),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.selected, required this.onChanged});

  final _DeadlineView selected;
  final ValueChanged<_DeadlineView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _ModeChip(label: 'Hôm nay', selected: selected == _DeadlineView.today, onTap: () => onChanged(_DeadlineView.today))),
        const SizedBox(width: 10),
        Expanded(child: _ModeChip(label: 'Tuần này', selected: selected == _DeadlineView.week, onTap: () => onChanged(_DeadlineView.week))),
        const SizedBox(width: 10),
        Expanded(child: _ModeChip(label: 'Quá hạn', selected: selected == _DeadlineView.overdue, onTap: () => onChanged(_DeadlineView.overdue))),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? StudyFlowPalette.textPrimary : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 14)),
        ],
      ),
    );
  }
}

class _TodayDeadlineCard extends StatelessWidget {
  const _TodayDeadlineCard({required this.deadline, required this.onTap});

  final DeadlineModel deadline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: StudyFlowSurfaceCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            StudyFlowIconBadge(icon: Icons.menu_book_rounded, backgroundColor: deadline.displayColor, size: 48, iconSize: 20, borderRadius: 16),
            const SizedBox(width: 12),
            Expanded(child: Text(deadline.title, style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(width: 8),
            _TagPill(label: _priorityText(deadline.priority), backgroundColor: _priorityColor(deadline.priority).withValues(alpha: 0.14), textColor: _priorityColor(deadline.priority)),
          ]),
          const SizedBox(height: 12),
          Row(children: <Widget>[
            const Icon(Icons.access_time_rounded, size: 16, color: StudyFlowPalette.textMuted),
            const SizedBox(width: 6),
            Text(deadline.dueTime ?? '23:59'),
          ]),
          const SizedBox(height: 10),
          Text('Tiến độ', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: <Widget>[
            Expanded(child: StudyFlowProgressBar(value: deadline.progress / 100, color: StudyFlowPalette.blue, height: 8, backgroundColor: const Color(0xFFABBDD7))),
            const SizedBox(width: 10),
            Text('${deadline.progress} %'),
          ]),
        ]),
      ),
    );
  }
}

class _WeekDeadlineCard extends StatelessWidget {
  const _WeekDeadlineCard({required this.deadline, required this.onTap, required this.onDelete});

  final DeadlineModel deadline;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: StudyFlowSurfaceCard(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StudyFlowIconBadge(icon: Icons.menu_book_rounded, backgroundColor: deadline.displayColor, size: 40, iconSize: 18, borderRadius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(deadline.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(children: <Widget>[
                  const Icon(Icons.event_outlined, size: 14, color: StudyFlowPalette.textMuted),
                  const SizedBox(width: 4),
                  Text(DateTimeUtils.toDbDate(deadline.dueDate)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_rounded, size: 14, color: StudyFlowPalette.textMuted),
                  const SizedBox(width: 4),
                  Text(deadline.dueTime ?? '23:59'),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            _TagPill(
              label: _deadlineCountdown(deadline),
              backgroundColor: _deadlineCountdownColor(deadline).withValues(alpha: 0.16),
              textColor: _deadlineCountdownColor(deadline),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverdueDeadlineCard extends StatelessWidget {
  const _OverdueDeadlineCard({required this.deadline, required this.onTap});

  final DeadlineModel deadline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: StudyFlowSurfaceCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Row(children: <Widget>[
          const StudyFlowIconBadge(icon: Icons.assignment_outlined, backgroundColor: StudyFlowPalette.orange, size: 40, iconSize: 18, borderRadius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(deadline.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(deadline.subjectName ?? 'Chung', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: StudyFlowPalette.textSecondary)),
              const SizedBox(height: 6),
              Row(children: <Widget>[
                const Icon(Icons.event_outlined, size: 14, color: StudyFlowPalette.textMuted),
                const SizedBox(width: 4),
                Text(DateTimeUtils.toDbDate(deadline.dueDate)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          const _TagPill(label: 'Quá hạn', backgroundColor: Color(0xFFFFE2E4), textColor: Color(0xFFE84E5C)),
        ]),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.backgroundColor, required this.textColor});

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}

class _InlineMessageCard extends StatelessWidget {
  const _InlineMessageCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return StudyFlowSurfaceCard(
      radius: 24,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: StudyFlowPalette.textSecondary)),
      ]),
    );
  }
}

DateTime _dayOnly(DateTime value) => DateTime(value.year, value.month, value.day);

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'T2';
    case DateTime.tuesday:
      return 'T3';
    case DateTime.wednesday:
      return 'T4';
    case DateTime.thursday:
      return 'T5';
    case DateTime.friday:
      return 'T6';
    case DateTime.saturday:
      return 'T7';
    default:
      return 'CN';
  }
}

String _priorityText(String priority) {
  switch (priority) {
    case 'High':
      return 'Khẩn cấp';
    case 'Low':
      return 'Thấp';
    default:
      return 'Bình thường';
  }
}

Color _priorityColor(String priority) {
  switch (priority) {
    case 'High':
      return const Color(0xFFE84E5C);
    case 'Low':
      return StudyFlowPalette.green;
    default:
      return const Color(0xFFB45309);
  }
}

String _deadlineCountdown(DeadlineModel deadline) {
  final int days = deadline.dueDate.difference(_dayOnly(DateTime.now())).inDays;
  if (days <= 0) return 'Hôm nay';
  return '$days ngày';
}

Color _deadlineCountdownColor(DeadlineModel deadline) {
  final int days = deadline.dueDate.difference(_dayOnly(DateTime.now())).inDays;
  if (days <= 0) return const Color(0xFFE84E5C);
  if (days <= 2) return StudyFlowPalette.orange;
  return StudyFlowPalette.green;
}


