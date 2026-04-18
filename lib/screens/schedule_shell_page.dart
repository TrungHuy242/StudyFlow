import 'package:flutter/material.dart';

import '../data/sample_schedule.dart';
import '../models/schedule_item.dart';
import 'schedule_detail_page.dart';
import 'schedule_form_page.dart';

enum CalendarMode { day, week, month }

class ScheduleShellPage extends StatefulWidget {
  const ScheduleShellPage({super.key});

  @override
  State<ScheduleShellPage> createState() => _ScheduleShellPageState();
}

class _ScheduleShellPageState extends State<ScheduleShellPage> {
  final List<ScheduleItem> _items = createSampleSchedule();
  int _navIndex = 1;
  CalendarMode _mode = CalendarMode.day;
  DateTime _selectedDate = DateTime(2026, 4, 6);

  List<ScheduleItem> get _orderedItems {
    final items = [..._items];
    items.sort((a, b) {
      final dayCompare = a.weekday.compareTo(b.weekday);
      if (dayCompare != 0) {
        return dayCompare;
      }
      return (a.start.hour * 60 + a.start.minute).compareTo(
        b.start.hour * 60 + b.start.minute,
      );
    });
    return items;
  }

  List<ScheduleItem> get _itemsForSelectedDate {
    return _orderedItems
        .where((item) => item.weekday == _selectedDate.weekday)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            const _PlaceholderTab(
              icon: Icons.home_outlined,
              title: 'Trang chủ',
            ),
            _buildSchedulePage(),
            const _PlaceholderTab(
              icon: Icons.check_box_outlined,
              title: 'Việc',
            ),
            const _PlaceholderTab(
              icon: Icons.bar_chart_rounded,
              title: 'Thống kê',
            ),
            const _PlaceholderTab(
              icon: Icons.person_outline_rounded,
              title: 'Tôi',
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEAF0FF),
        onDestinationSelected: (index) => setState(() => _navIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box_rounded),
            label: 'Việc',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Tôi',
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePage() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
            child: Column(
              children: [
                _ScheduleHeader(
                  title: switch (_mode) {
                    CalendarMode.day => 'Lịch học',
                    CalendarMode.week => 'Lịch tuần',
                    CalendarMode.month => 'Lịch tháng',
                  },
                  onAdd: _openAddSchedule,
                  onClear: _items.isEmpty
                      ? null
                      : () => setState(() => _items.clear()),
                ),
                const SizedBox(height: 22),
                _CalendarSegmentedControl(
                  value: _mode,
                  onChanged: (mode) => setState(() => _mode = mode),
                ),
                const SizedBox(height: 18),
                _buildContentHeader(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          sliver: SliverToBoxAdapter(child: _buildModeContent()),
        ),
      ],
    );
  }

  Widget _buildContentHeader() {
    return switch (_mode) {
      CalendarMode.day => _DaySwitcher(
        selectedDate: _selectedDate,
        onPrevious: () => setState(
          () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)),
        ),
        onNext: () => setState(
          () => _selectedDate = _selectedDate.add(const Duration(days: 1)),
        ),
      ),
      CalendarMode.week => _WeekSwitcher(
        weekStart: _weekStart(_selectedDate),
        onPrevious: () => setState(
          () => _selectedDate = _selectedDate.subtract(const Duration(days: 7)),
        ),
        onNext: () => setState(
          () => _selectedDate = _selectedDate.add(const Duration(days: 7)),
        ),
      ),
      CalendarMode.month => _MonthSwitcher(
        selectedDate: _selectedDate,
        onPrevious: () => setState(
          () => _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month - 1,
            1,
          ),
        ),
        onNext: () => setState(
          () => _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + 1,
            1,
          ),
        ),
      ),
    };
  }

  Widget _buildModeContent() {
    if (_items.isEmpty) {
      return _EmptySchedule(onAdd: _openAddSchedule);
    }

    return switch (_mode) {
      CalendarMode.day => _buildDayList(),
      CalendarMode.week => _buildWeekView(),
      CalendarMode.month => _buildMonthView(),
    };
  }

  Widget _buildDayList() {
    final dayItems = _itemsForSelectedDate;

    if (dayItems.isEmpty) {
      return _EmptySchedule(
        title: 'Không có lịch trong ngày này',
        description: 'Thêm lịch học để quản lý thời gian biểu của bạn.',
        onAdd: _openAddSchedule,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hôm nay có ${dayItems.length} lớp',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        for (final item in dayItems) ...[
          _ScheduleCard(item: item, onTap: () => _openDetail(item)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildWeekView() {
    final start = _weekStart(_selectedDate);

    return Column(
      children: [
        _WeekDaysRow(
          weekStart: start,
          selectedDate: _selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 288,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final date = start.add(Duration(days: index));
              final dayItems = _orderedItems
                  .where((item) => item.weekday == date.weekday)
                  .toList();

              return _WeekColumn(
                date: date,
                items: dayItems,
                selected: _isSameDay(date, _selectedDate),
                onTapDay: () => setState(() => _selectedDate = date),
                onTapItem: _openDetail,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView() {
    final selectedItems = _itemsForSelectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MonthGrid(
          selectedDate: _selectedDate,
          items: _orderedItems,
          onDateSelected: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 18),
        Text(
          'Sự kiện ngày ${_selectedDate.day}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (selectedItems.isEmpty)
          const _SoftPanel(
            child: Text(
              'Không có lớp học nào trong ngày đã chọn.',
              style: TextStyle(color: Color(0xFF667085)),
            ),
          )
        else
          for (final item in selectedItems) ...[
            _CompactScheduleTile(item: item, onTap: () => _openDetail(item)),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Future<void> _openAddSchedule() async {
    final item = await Navigator.of(context).push<ScheduleItem>(
      MaterialPageRoute(builder: (_) => const ScheduleFormPage()),
    );

    if (!mounted || item == null) {
      return;
    }

    setState(() {
      _items.add(item);
      _selectedDate = _dateInSelectedWeekFor(item.weekday);
    });
  }

  void _openDetail(ScheduleItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleDetailPage(
          item: item,
          onChanged: _replaceItem,
          onDeleted: _deleteItem,
        ),
      ),
    );
  }

  void _replaceItem(ScheduleItem updated) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == updated.id);
      if (index == -1) {
        return;
      }
      _items[index] = updated;
      _selectedDate = _dateInSelectedWeekFor(updated.weekday);
    });
  }

  void _deleteItem(String id) {
    setState(() => _items.removeWhere((item) => item.id == id));
  }

  DateTime _dateInSelectedWeekFor(int weekday) {
    return _weekStart(_selectedDate).add(Duration(days: weekday - 1));
  }

  DateTime _weekStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - DateTime.monday));
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.title,
    required this.onAdd,
    required this.onClear,
  });

  final String title;
  final VoidCallback onAdd;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Tùy chọn lịch',
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (value) {
            if (value == 'clear') {
              onClear?.call();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clear',
              enabled: onClear != null,
              child: const Text('Xóa toàn bộ lịch mẫu'),
            ),
          ],
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          tooltip: 'Thêm lịch học',
          onPressed: onAdd,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF3F6DF6),
            foregroundColor: Colors.white,
            fixedSize: const Size.square(40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _CalendarSegmentedControl extends StatelessWidget {
  const _CalendarSegmentedControl({
    required this.value,
    required this.onChanged,
  });

  final CalendarMode value;
  final ValueChanged<CalendarMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EF)),
      ),
      child: Row(
        children: [
          _SegmentButton(
            label: 'Ngày',
            selected: value == CalendarMode.day,
            onTap: () => onChanged(CalendarMode.day),
          ),
          _SegmentButton(
            label: 'Tuần',
            selected: value == CalendarMode.week,
            onTap: () => onChanged(CalendarMode.week),
          ),
          _SegmentButton(
            label: 'Tháng',
            selected: value == CalendarMode.month,
            onTap: () => onChanged(CalendarMode.month),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
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
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF0FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFF315CE7)
                  : const Color(0xFF667085),
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySwitcher extends StatelessWidget {
  const _DaySwitcher({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _SwitchPanel(
      onPrevious: onPrevious,
      onNext: onNext,
      child: Column(
        children: [
          Text(
            weekdayName(selectedDate.weekday),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${selectedDate.day} tháng ${selectedDate.month}, ${selectedDate.year}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekSwitcher extends StatelessWidget {
  const _WeekSwitcher({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final weekNumber =
        ((weekStart.difference(DateTime(weekStart.year, 1, 1)).inDays +
                    DateTime(weekStart.year, 1, 1).weekday) /
                7)
            .ceil();

    return _SwitchPanel(
      onPrevious: onPrevious,
      onNext: onNext,
      child: Text(
        'Tuần $weekNumber - ${weekStart.year}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF101828),
        ),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _SwitchPanel(
      onPrevious: onPrevious,
      onNext: onNext,
      child: Text(
        'Tháng ${selectedDate.month}, ${selectedDate.year}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF101828),
        ),
      ),
    );
  }
}

class _SwitchPanel extends StatelessWidget {
  const _SwitchPanel({
    required this.child,
    required this.onPrevious,
    required this.onNext,
  });

  final Widget child;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EF)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Trước',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(child: Center(child: child)),
          IconButton(
            tooltip: 'Sau',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item, required this.onTap});

  final ScheduleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 64,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF101828),
                            ),
                          ),
                        ),
                        Text(
                          formatTimeOfDay(item.start),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.schedule_rounded,
                          label: item.timeRange(context),
                        ),
                        _MetaChip(
                          icon: Icons.location_on_outlined,
                          label: item.room,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TypePill(item: item),
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

class _CompactScheduleTile extends StatelessWidget {
  const _CompactScheduleTile({required this.item, required this.onTap});

  final ScheduleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5E7EF)),
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.menu_book_rounded, color: item.color),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${item.timeRange(context)} • ${item.room}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF667085)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF667085),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        item.modeLabel,
        style: TextStyle(
          color: item.color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WeekDaysRow extends StatelessWidget {
  const _WeekDaysRow({
    required this.weekStart,
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime weekStart;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final selected = _isSameDay(date, selectedDate);

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF3F6DF6) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    compactWeekdayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : const Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 15,
                      color: selected ? Colors.white : const Color(0xFF101828),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WeekColumn extends StatelessWidget {
  const _WeekColumn({
    required this.date,
    required this.items,
    required this.selected,
    required this.onTapDay,
    required this.onTapItem,
  });

  final DateTime date;
  final List<ScheduleItem> items;
  final bool selected;
  final VoidCallback onTapDay;
  final ValueChanged<ScheduleItem> onTapItem;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTapDay,
      child: Container(
        width: 118,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF0FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF3F6DF6) : const Color(0xFFE5E7EF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${compactWeekdayName(date.weekday)} ${date.day}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text(
                'Trống',
                style: TextStyle(
                  color: Color(0xFF98A2B3),
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              for (final item in items) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onTapItem(item),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.shortTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${formatTimeOfDay(item.start)}-'
                          '${formatTimeOfDay(item.end)}',
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.selectedDate,
    required this.items,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final List<ScheduleItem> items;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedDate.year, selectedDate.month);
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );
    final leading = firstDay.weekday - DateTime.monday;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;

    return _SoftPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: List.generate(7, (index) {
              return Expanded(
                child: Center(
                  child: Text(
                    compactWeekdayName(index + 1),
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.86,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leading + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                selectedDate.year,
                selectedDate.month,
                dayNumber,
              );
              final selected = _isSameDay(date, selectedDate);
              final hasClass = items.any(
                (item) => item.weekday == date.weekday,
              );

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onDateSelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF3F6DF6)
                        : hasClass
                        ? const Color(0xFFEAF0FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF101828),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: hasClass
                              ? (selected
                                    ? Colors.white
                                    : const Color(0xFF3F6DF6))
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({
    required this.onAdd,
    this.title = 'Chưa có lịch học',
    this.description =
        'Thêm lịch học để xem và quản lý thời gian biểu của bạn.',
  });

  final String title;
  final String description;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF3F6DF6),
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 246,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm lịch học đầu tiên'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EF)),
      ),
      child: child,
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: const Color(0xFF3F6DF6)),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
