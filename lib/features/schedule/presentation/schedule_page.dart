import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../subjects/data/subject_model.dart';
import '../../subjects/data/subject_repository.dart';
import '../data/schedule_model.dart';
import '../data/schedule_repository.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

enum _ScheduleViewMode { day, week, month }

class _SchedulePageState extends State<SchedulePage> {
  late final ScheduleRepository _scheduleRepository;
  late final SubjectRepository _subjectRepository;
  late Future<_SchedulePageData> _future;
  bool _initialized = false;
  _ScheduleViewMode _viewMode = _ScheduleViewMode.day;
  DateTime _selectedDate = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final DatabaseService databaseService = context.read<DatabaseService>();
    _scheduleRepository = ScheduleRepository(databaseService);
    _subjectRepository = SubjectRepository(databaseService);
    _future = _loadData();
    _initialized = true;
  }

  Future<_SchedulePageData> _loadData() async {
    final List<ScheduleModel> schedules = await _scheduleRepository.getSchedules();
    final List<SubjectModel> subjects = await _subjectRepository.getSubjects();
    return _SchedulePageData(schedules: schedules, subjects: subjects);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<void> _openAdd(_SchedulePageData data) async {
    if (data.subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm môn học trước khi tạo lịch học.')),
      );
      return;
    }
    final bool? changed = await context.push<bool>('/calendar/add');
    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _openDetail(ScheduleModel entry) async {
    if (entry.id == null) {
      return;
    }
    final bool? changed = await context.push<bool>('/calendar/${entry.id}');
    if (changed == true) {
      await _refresh();
    }
  }

  void _stepDate(int delta) {
    setState(() {
      switch (_viewMode) {
        case _ScheduleViewMode.day:
          _selectedDate = _selectedDate.add(Duration(days: delta));
          break;
        case _ScheduleViewMode.week:
          _selectedDate = _selectedDate.add(Duration(days: 7 * delta));
          break;
        case _ScheduleViewMode.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
          break;
      }
    });
  }

  List<ScheduleModel> _entriesForDay(List<ScheduleModel> schedules, int weekday) {
    return schedules.where((ScheduleModel item) => item.weekday == weekday).toList()
      ..sort((ScheduleModel a, ScheduleModel b) => a.startTime.compareTo(b.startTime));
  }

  DateTime get _weekStart => _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

  String _headerTitle() {
    switch (_viewMode) {
      case _ScheduleViewMode.day:
        return _weekdayLabel(_selectedDate.weekday);
      case _ScheduleViewMode.week:
        return 'Tuần học';
      case _ScheduleViewMode.month:
        return 'Tháng ${_selectedDate.month}, ${_selectedDate.year}';
    }
  }

  String _headerSubtitle() {
    switch (_viewMode) {
      case _ScheduleViewMode.day:
        return '${_selectedDate.day} tháng ${_selectedDate.month}, ${_selectedDate.year}';
      case _ScheduleViewMode.week:
        final DateTime weekEnd = _weekStart.add(const Duration(days: 6));
        return '${_weekStart.day}/${_weekStart.month} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';
      case _ScheduleViewMode.month:
        return 'Lịch học lặp theo tuần trong tháng';
    }
  }

  Widget _buildContent(_SchedulePageData data) {
    switch (_viewMode) {
      case _ScheduleViewMode.day:
        final List<ScheduleModel> entries = _entriesForDay(data.schedules, _selectedDate.weekday);
        if (entries.isEmpty) {
          return _ScheduleEmptyState(
            title: 'Không có lịch học hôm nay',
            subtitle: 'Thêm buổi học để bắt đầu quản lý thời khóa biểu.',
            onAdd: () => _openAdd(data),
          );
        }
        return Column(
          children: entries.map((ScheduleModel entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ScheduleCard(entry: entry, onTap: () => _openDetail(entry)),
            );
          }).toList(),
        );
      case _ScheduleViewMode.week:
        return Column(
          children: List<Widget>.generate(7, (int index) {
            final int weekday = index + 1;
            final List<ScheduleModel> entries = _entriesForDay(data.schedules, weekday);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ScheduleWeekSection(
                weekdayLabel: _weekdayLabel(weekday),
                entries: entries,
                onTapEntry: _openDetail,
              ),
            );
          }),
        );
      case _ScheduleViewMode.month:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.55,
          ),
          itemBuilder: (BuildContext context, int index) {
            final int weekday = index + 1;
            final List<ScheduleModel> entries = _entriesForDay(data.schedules, weekday);
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDate = _weekStart.add(Duration(days: index));
                  _viewMode = _ScheduleViewMode.day;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedDate.weekday == weekday
                      ? StudyFlowPalette.blue
                      : entries.isNotEmpty
                          ? StudyFlowPalette.blue.withValues(alpha: 0.08)
                          : StudyFlowPalette.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: entries.isNotEmpty && _selectedDate.weekday != weekday
                        ? StudyFlowPalette.blue.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      _weekdayShortLabel(weekday),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _selectedDate.weekday == weekday
                            ? Colors.white
                            : StudyFlowPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_weekStart.add(Duration(days: index)).day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _selectedDate.weekday == weekday
                            ? Colors.white
                            : StudyFlowPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entries.isNotEmpty
                            ? (_selectedDate.weekday == weekday ? Colors.white : StudyFlowPalette.blue)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }

  String _weekdayLabel(int weekday) {
    const List<String> labels = <String>[
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    return labels[weekday - 1];
  }

  String _weekdayShortLabel(int weekday) {
    const List<String> labels = <String>['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return labels[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<_SchedulePageData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_SchedulePageData> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final _SchedulePageData data = snapshot.data ??
              const _SchedulePageData(
                schedules: <ScheduleModel>[],
                subjects: <SubjectModel>[],
              );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('Lịch học', style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      StudyFlowCircleIconButton(
                        icon: Icons.add_rounded,
                        backgroundColor: StudyFlowPalette.blue,
                        foregroundColor: Colors.white,
                        size: 46,
                        onTap: () => _openAdd(data),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ScheduleModeTabs(
                    currentMode: _viewMode,
                    onChanged: (_ScheduleViewMode mode) {
                      setState(() {
                        _viewMode = mode;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: StudyFlowPalette.surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: <Widget>[
                        StudyFlowCircleIconButton(
                          icon: Icons.chevron_left_rounded,
                          size: 34,
                          backgroundColor: Colors.white,
                          foregroundColor: StudyFlowPalette.textSecondary,
                          onTap: () => _stepDate(-1),
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Text(_headerTitle(), style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(_headerSubtitle(), style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        StudyFlowCircleIconButton(
                          icon: Icons.chevron_right_rounded,
                          size: 34,
                          backgroundColor: Colors.white,
                          foregroundColor: StudyFlowPalette.textSecondary,
                          onTap: () => _stepDate(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: <Widget>[
                          _buildContent(data),
                        ],
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

class _ScheduleModeTabs extends StatelessWidget {
  const _ScheduleModeTabs({
    required this.currentMode,
    required this.onChanged,
  });

  final _ScheduleViewMode currentMode;
  final ValueChanged<_ScheduleViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StudyFlowPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          _TabChip(
            label: 'Ngày',
            selected: currentMode == _ScheduleViewMode.day,
            onTap: () => onChanged(_ScheduleViewMode.day),
          ),
          _TabChip(
            label: 'Tuần',
            selected: currentMode == _ScheduleViewMode.week,
            onTap: () => onChanged(_ScheduleViewMode.week),
          ),
          _TabChip(
            label: 'Tháng',
            selected: currentMode == _ScheduleViewMode.month,
            onTap: () => onChanged(_ScheduleViewMode.month),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? StudyFlowPalette.textPrimary : StudyFlowPalette.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.entry,
    required this.onTap,
  });

  final ScheduleModel entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 6,
                height: 66,
                decoration: BoxDecoration(
                  color: entry.displayColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            entry.subjectName ?? 'Môn học',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                        ),
                        Text(entry.startTime, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.schedule_rounded, size: 16, color: StudyFlowPalette.textMuted),
                        const SizedBox(width: 6),
                        Text(entry.timeRange, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(width: 14),
                        const Icon(Icons.location_on_outlined, size: 16, color: StudyFlowPalette.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          entry.room.isEmpty ? 'Chưa có phòng' : entry.room,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: StudyFlowPalette.surfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        entry.type,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: StudyFlowPalette.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleWeekSection extends StatelessWidget {
  const _ScheduleWeekSection({
    required this.weekdayLabel,
    required this.entries,
    required this.onTapEntry,
  });

  final String weekdayLabel;
  final List<ScheduleModel> entries;
  final ValueChanged<ScheduleModel> onTapEntry;

  @override
  Widget build(BuildContext context) {
    return StudyFlowSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(weekdayLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text('Không có lịch học', style: Theme.of(context).textTheme.bodyMedium)
          else
            Column(
              children: entries.map((ScheduleModel entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ScheduleCard(
                    entry: entry,
                    onTap: () => onTapEntry(entry),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState({
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: <Widget>[
          const StudyFlowIconBadge(
            icon: Icons.event_note_rounded,
            backgroundColor: Color(0xFFF0F5FD),
            foregroundColor: Color(0xFFAABBD2),
            size: 80,
            iconSize: 36,
            borderRadius: 26,
          ),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          StudyFlowGradientButton(label: 'Thêm lịch học', onTap: onAdd),
        ],
      ),
    );
  }
}

class _SchedulePageData {
  const _SchedulePageData({
    required this.schedules,
    required this.subjects,
  });

  final List<ScheduleModel> schedules;
  final List<SubjectModel> subjects;
}
