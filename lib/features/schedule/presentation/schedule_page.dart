import 'dart:math' as math;

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
    final List<ScheduleModel> schedules =
        await _scheduleRepository.getSchedules();
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
        const SnackBar(
          content: Text('Thêm môn học trước khi tạo lịch học.'),
        ),
      );
      return;
    }
    final bool? changed = await context.push<bool>('/calendar/add');
    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _openDetail(ScheduleModel entry) async {
    final int? entryId = entry.id;
    if (entryId == null) {
      return;
    }
    final bool? changed = await context.push<bool>('/calendar/$entryId');
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
          _selectedDate = _selectedDate.add(Duration(days: delta * 7));
          break;
        case _ScheduleViewMode.month:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + delta,
            math.min(
              _selectedDate.day,
              _daysInMonth(_selectedDate.year, _selectedDate.month + delta),
            ),
          );
          break;
      }
    });
  }

  List<ScheduleModel> _entriesForWeekday(
    List<ScheduleModel> schedules,
    int weekday,
  ) {
    return schedules
        .where((ScheduleModel item) => item.weekday == weekday)
        .toList()
      ..sort((ScheduleModel a, ScheduleModel b) =>
          a.startTime.compareTo(b.startTime));
  }

  List<ScheduleModel> _entriesForDate(
      List<ScheduleModel> schedules, DateTime date) {
    return _entriesForWeekday(schedules, date.weekday);
  }

  DateTime get _weekStart {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    ).subtract(Duration(days: _selectedDate.weekday - 1));
  }

  List<DateTime> get _weekDays {
    return List<DateTime>.generate(
      7,
      (int index) => _weekStart.add(Duration(days: index)),
    );
  }

  int _weekNumber(DateTime date) {
    final DateTime target = DateTime(date.year, date.month, date.day);
    final DateTime thursday = target.add(Duration(days: 4 - target.weekday));
    final DateTime firstThursday = DateTime(thursday.year, 1, 4);
    return ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;
  }

  List<DateTime?> _monthCells(DateTime selectedMonth) {
    final DateTime firstDay =
        DateTime(selectedMonth.year, selectedMonth.month, 1);
    final int leadingEmpty = firstDay.weekday - 1;
    final int totalDays = _daysInMonth(selectedMonth.year, selectedMonth.month);
    final List<DateTime?> cells = <DateTime?>[
      ...List<DateTime?>.filled(leadingEmpty, null),
      ...List<DateTime>.generate(
        totalDays,
        (int index) =>
            DateTime(selectedMonth.year, selectedMonth.month, index + 1),
      ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  int _daysInMonth(int year, int month) {
    final DateTime normalized = DateTime(year, month + 1, 0);
    return normalized.day;
  }

  String _pageTitle() {
    switch (_viewMode) {
      case _ScheduleViewMode.day:
        return 'Lịch học';
      case _ScheduleViewMode.week:
        return 'Lịch tuần';
      case _ScheduleViewMode.month:
        return 'Lịch tháng';
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

  String _monthLabel(int month) {
    const List<String> labels = <String>[
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12',
    ];
    return labels[month - 1];
  }

  String _dateTitle(DateTime date) {
    return '${date.day} ${_monthLabel(date.month)}, ${date.year}';
  }

  String _displayType(String value) {
    switch (value.toLowerCase()) {
      case 'lecture':
      case 'lý thuyết':
        return 'Lý thuyết';
      case 'practice':
      case 'thực hành':
        return 'Thực hành';
      case 'seminar':
        return 'Seminar';
      default:
        return value;
    }
  }

  String _shortSubjectName(String value) {
    final List<String> words = value
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.length == 1) {
      return value;
    }
    if (words.length == 2) {
      return '${words.first}\n${words.last}';
    }
    return words.take(2).join(' ');
  }

  Widget _buildDayView(_SchedulePageData data) {
    final List<ScheduleModel> entries =
        _entriesForDate(data.schedules, _selectedDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ScheduleHeaderPanel(
          title: _weekdayLabel(_selectedDate.weekday),
          subtitle: _dateTitle(_selectedDate),
          onPrevious: () => _stepDate(-1),
          onNext: () => _stepDate(1),
        ),
        const SizedBox(height: 18),
        if (entries.isEmpty)
          _ScheduleInnerEmptyState(
            title: 'Không có lịch học trong ngày này',
            subtitle:
                'Chọn ngày khác hoặc thêm lịch học mới cho thời khóa biểu của bạn.',
            onAdd: () => _openAdd(data),
          )
        else
          Column(
            children: entries.map((ScheduleModel entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ScheduleListCard(
                  entry: entry,
                  typeLabel: _displayType(entry.type),
                  onTap: () => _openDetail(entry),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildWeekView(_SchedulePageData data) {
    final List<DateTime> days = _weekDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ScheduleHeaderPanel(
          title: 'Tuần ${_weekNumber(_selectedDate)} - ${_selectedDate.year}',
          onPrevious: () => _stepDate(-1),
          onNext: () => _stepDate(1),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 66,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final DateTime day = days[index];
              final bool selected = day.year == _selectedDate.year &&
                  day.month == _selectedDate.month &&
                  day.day == _selectedDate.day;
              return _WeekDayChip(
                label: _weekdayShortLabel(day.weekday),
                dayNumber: '${day.day}',
                selected: selected,
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        _WeekTimelineBoard(
          days: days,
          schedules: data.schedules,
          onTapEntry: _openDetail,
          shortSubjectName: _shortSubjectName,
        ),
      ],
    );
  }

  Widget _buildMonthView(_SchedulePageData data) {
    final List<DateTime?> cells = _monthCells(_selectedDate);
    final List<ScheduleModel> selectedDayEntries =
        _entriesForDate(data.schedules, _selectedDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ScheduleHeaderPanel(
          title: 'Tháng ${_selectedDate.month}, ${_selectedDate.year}',
          onPrevious: () => _stepDate(-1),
          onNext: () => _stepDate(1),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: List<Widget>.generate(7, (int index) {
              return Expanded(
                child: Center(
                  child: Text(
                    _weekdayShortLabel(index + 1),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (BuildContext context, int index) {
            final DateTime? date = cells[index];
            if (date == null) {
              return const SizedBox.shrink();
            }
            final bool isSelected = date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;
            final bool hasEntries =
                _entriesForDate(data.schedules, date).isNotEmpty;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? StudyFlowPalette.blue : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? StudyFlowPalette.blue
                        : StudyFlowPalette.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF334155),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasEntries
                            ? (isSelected
                                ? Colors.white
                                : StudyFlowPalette.blue)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        Text(
          'Sự kiện ngày ${_selectedDate.day}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 14),
        if (selectedDayEntries.isEmpty)
          _ScheduleInnerEmptyState(
            title: 'Không có lịch học trong ngày này',
            subtitle:
                'Chọn ngày khác trong tháng để xem các buổi học đã lên lịch.',
            onAdd: () => _openAdd(data),
            compact: true,
          )
        else
          Column(
            children: selectedDayEntries.map((ScheduleModel entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ScheduleEventRow(
                  entry: entry,
                  onTap: () => _openDetail(entry),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildContent(_SchedulePageData data) {
    if (data.schedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 72),
        child: _ScheduleGlobalEmptyState(onAdd: () => _openAdd(data)),
      );
    }

    switch (_viewMode) {
      case _ScheduleViewMode.day:
        return _buildDayView(data);
      case _ScheduleViewMode.week:
        return _buildWeekView(data);
      case _ScheduleViewMode.month:
        return _buildMonthView(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<_SchedulePageData>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<_SchedulePageData> snapshot) {
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _pageTitle(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: const Color(0xFF0F172A),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      StudyFlowCircleIconButton(
                        icon: Icons.add_rounded,
                        backgroundColor: StudyFlowPalette.blue,
                        foregroundColor: Colors.white,
                        size: 44,
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
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StudyFlowPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
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
          curve: Curves.easeOut,
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

class _ScheduleHeaderPanel extends StatelessWidget {
  const _ScheduleHeaderPanel({
    required this.title,
    this.subtitle,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StudyFlowPalette.border),
        boxShadow: StudyFlowPalette.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          StudyFlowCircleIconButton(
            icon: Icons.chevron_left_rounded,
            size: 36,
            backgroundColor: StudyFlowPalette.surfaceSoft,
            foregroundColor: StudyFlowPalette.textSecondary,
            onTap: onPrevious,
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 14,
                        ),
                  ),
                ],
              ],
            ),
          ),
          StudyFlowCircleIconButton(
            icon: Icons.chevron_right_rounded,
            size: 36,
            backgroundColor: StudyFlowPalette.surfaceSoft,
            foregroundColor: StudyFlowPalette.textSecondary,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _ScheduleListCard extends StatelessWidget {
  const _ScheduleListCard({
    required this.entry,
    required this.typeLabel,
    required this.onTap,
  });

  final ScheduleModel entry;
  final String typeLabel;
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
          padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 6,
                height: 62,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            entry.subjectName ?? 'Môn học',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          entry.startTime,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.timeRange,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF64748B),
                                  ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.room.isEmpty ? 'Chưa có phòng' : entry.room,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF64748B),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      typeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF475569),
                            fontSize: 12,
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

class _WeekDayChip extends StatelessWidget {
  const _WeekDayChip({
    required this.label,
    required this.dayNumber,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String dayNumber;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        decoration: BoxDecoration(
          color: selected
              ? StudyFlowPalette.blue.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? StudyFlowPalette.blue : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNumber,
              style: TextStyle(
                color:
                    selected ? StudyFlowPalette.blue : const Color(0xFF475569),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekTimelineBoard extends StatelessWidget {
  const _WeekTimelineBoard({
    required this.days,
    required this.schedules,
    required this.onTapEntry,
    required this.shortSubjectName,
  });

  final List<DateTime> days;
  final List<ScheduleModel> schedules;
  final ValueChanged<ScheduleModel> onTapEntry;
  final String Function(String value) shortSubjectName;

  int _timeToMinutes(String value) {
    final List<String> parts = value.split(':');
    return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return const SizedBox.shrink();
    }

    final int earliest = schedules
        .map((ScheduleModel schedule) => _timeToMinutes(schedule.startTime))
        .reduce(math.min);
    final int latest = schedules
        .map((ScheduleModel schedule) => _timeToMinutes(schedule.endTime))
        .reduce(math.max);
    final int minMinutes = math.max(360, earliest - 30);
    final int maxMinutes = math.min(1320, latest + 30);
    const double boardHeight = 340;
    final int spanMinutes = math.max(120, maxMinutes - minMinutes);

    return Container(
      height: boardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: StudyFlowPalette.border),
        boxShadow: StudyFlowPalette.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const double gap = 6;
          final double columnWidth = (constraints.maxWidth - (gap * 6)) / 7;
          return Stack(
            children: <Widget>[
              for (int i = 1; i < 4; i++)
                Positioned(
                  top: (boardHeight - 26) * (i / 4),
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: StudyFlowPalette.surfaceSoft,
                  ),
                ),
              ...days.asMap().entries.map((MapEntry<int, DateTime> dayEntry) {
                final int dayIndex = dayEntry.key;
                final int weekday = dayEntry.value.weekday;
                final List<ScheduleModel> daySchedules = schedules
                    .where(
                        (ScheduleModel schedule) => schedule.weekday == weekday)
                    .toList()
                  ..sort((ScheduleModel a, ScheduleModel b) =>
                      a.startTime.compareTo(b.startTime));

                return Positioned(
                  left: dayIndex * (columnWidth + gap),
                  top: 0,
                  width: columnWidth,
                  bottom: 0,
                  child: Stack(
                    children: daySchedules.map((ScheduleModel schedule) {
                      final int start = _timeToMinutes(schedule.startTime);
                      final int end = _timeToMinutes(schedule.endTime);
                      final double top = ((start - minMinutes) / spanMinutes) *
                          (boardHeight - 26);
                      final double height = math.max(
                        56,
                        ((end - start) / spanMinutes) * (boardHeight - 26),
                      );
                      return Positioned(
                        top: top.clamp(0, boardHeight - 78),
                        left: 0,
                        right: 0,
                        height: height,
                        child: GestureDetector(
                          onTap: () => onTapEntry(schedule),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  schedule.displayColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: schedule.displayColor
                                    .withValues(alpha: 0.28),
                              ),
                            ),
                            child: DefaultTextStyle(
                              style: TextStyle(
                                color: schedule.displayColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    shortSubjectName(
                                        schedule.subjectName ?? 'Môn học'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${schedule.startTime}-${schedule.endTime}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: schedule.displayColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      height: 1,
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
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ScheduleEventRow extends StatelessWidget {
  const _ScheduleEventRow({
    required this.entry,
    required this.onTap,
  });

  final ScheduleModel entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: StudyFlowPalette.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: entry.displayColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.subjectName ?? 'Môn học',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.timeRange,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
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

class _ScheduleGlobalEmptyState extends StatelessWidget {
  const _ScheduleGlobalEmptyState({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: StudyFlowPalette.surfaceSoft,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.event_note_rounded,
            color: Color(0xFF94A3B8),
            size: 42,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Chưa có lịch học',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Thêm lịch học để xem và quản lý thời\ngian biểu của bạn',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 28),
        StudyFlowGradientButton(
          label: 'Thêm lịch học đầu tiên',
          onTap: onAdd,
          height: 54,
        ),
      ],
    );
  }
}

class _ScheduleInnerEmptyState extends StatelessWidget {
  const _ScheduleInnerEmptyState({
    required this.title,
    required this.subtitle,
    required this.onAdd,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: compact ? 20 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StudyFlowPalette.border),
      ),
      child: Column(
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 18),
          StudyFlowGradientButton(
            label: 'Thêm lịch học',
            onTap: onAdd,
            height: 48,
          ),
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
