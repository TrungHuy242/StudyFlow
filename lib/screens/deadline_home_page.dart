import 'package:flutter/material.dart';

import '../data/sample_deadlines.dart';
import '../models/deadline_item.dart';
import 'deadline_detail_page.dart';
import 'deadline_form_page.dart';

enum DeadlineView { all, today, week, overdue }

class DeadlineHomePage extends StatefulWidget {
  const DeadlineHomePage({super.key});

  @override
  State<DeadlineHomePage> createState() => _DeadlineHomePageState();
}

class _DeadlineHomePageState extends State<DeadlineHomePage> {
  final List<DeadlineItem> _items = createSampleDeadlines();
  final TextEditingController _searchController = TextEditingController();
  int _navIndex = 2;
  DeadlineView _view = DeadlineView.all;
  DeadlinePriority? _priorityFilter;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DeadlineItem> get _orderedItems {
    final items = [..._items];
    items.sort((a, b) => a.dueDateTime.compareTo(b.dueDateTime));
    return items;
  }

  List<DeadlineItem> get _visibleItems {
    return _orderedItems.where((item) {
      final matchesSearch =
          _query.trim().isEmpty ||
          item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.subject.toLowerCase().contains(_query.toLowerCase()) ||
          item.category.toLowerCase().contains(_query.toLowerCase());
      final matchesPriority =
          _priorityFilter == null || item.priority == _priorityFilter;
      return matchesSearch && matchesPriority;
    }).toList();
  }

  List<DeadlineItem> get _todayItems {
    return _visibleItems.where((item) => item.isDueToday(demoNow)).toList();
  }

  List<DeadlineItem> get _weekItems {
    final start = _weekStart(demoNow);
    final end = start.add(const Duration(days: 7));
    return _visibleItems
        .where(
          (item) => !item.dueDate.isBefore(start) && item.dueDate.isBefore(end),
        )
        .toList();
  }

  List<DeadlineItem> get _overdueItems {
    return _visibleItems.where((item) => item.isOverdue(demoNow)).toList();
  }

  int get _unfinishedCount {
    return _items.where((item) => !item.completed).length;
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
            const _PlaceholderTab(
              icon: Icons.calendar_today_outlined,
              title: 'Lịch',
            ),
            _buildDeadlinePage(),
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
        indicatorColor: const Color(0xFFEAF2FF),
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

  Widget _buildDeadlinePage() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  unfinishedCount: _unfinishedCount,
                  onAdd: _openAddDeadline,
                  onClear: _items.isEmpty
                      ? null
                      : () => setState(() => _items.clear()),
                  onRestore: _items.isEmpty
                      ? () => setState(() {
                          _items.addAll(createSampleDeadlines());
                        })
                      : null,
                ),
                const SizedBox(height: 18),
                _SearchAndFilter(
                  controller: _searchController,
                  priorityFilter: _priorityFilter,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onPriorityChanged: (value) =>
                      setState(() => _priorityFilter = value),
                ),
                const SizedBox(height: 18),
                _ViewTabs(
                  value: _view,
                  onChanged: (view) => setState(() => _view = view),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          sliver: SliverToBoxAdapter(child: _buildBody()),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_items.isEmpty) {
      return _EmptyState(
        title: 'Chưa có deadline',
        description:
            'Thêm deadline để theo dõi các nhiệm vụ và bài tập quan trọng.',
        buttonLabel: 'Thêm deadline đầu tiên',
        onAdd: _openAddDeadline,
      );
    }

    final items = switch (_view) {
      DeadlineView.all => _visibleItems,
      DeadlineView.today => _todayItems,
      DeadlineView.week => _weekItems,
      DeadlineView.overdue => _overdueItems,
    };

    if (items.isEmpty) {
      return _EmptyState(
        title: 'Không tìm thấy deadline',
        description: 'Thử đổi từ khóa tìm kiếm hoặc bộ lọc ưu tiên.',
        buttonLabel: 'Tạo deadline mới',
        onAdd: _openAddDeadline,
      );
    }

    return switch (_view) {
      DeadlineView.all => _buildAllList(),
      DeadlineView.today => _TodayView(items: items, onTap: _openDetail),
      DeadlineView.week => _WeekView(items: items, onTap: _openDetail),
      DeadlineView.overdue => _OverdueView(items: items, onTap: _openDetail),
    };
  }

  Widget _buildAllList() {
    final overdue = _overdueItems;
    final upcoming = _visibleItems
        .where((item) => !item.isOverdue(demoNow))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overdue.isNotEmpty) ...[
          _SectionTitle(
            icon: Icons.warning_amber_rounded,
            title: 'Quá hạn',
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 10),
          for (final item in overdue) ...[
            DeadlineCard(item: item, onTap: () => _openDetail(item)),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 10),
        ],
        const _SectionTitle(
          icon: Icons.schedule_rounded,
          title: 'Sắp tới',
          color: Color(0xFF101828),
        ),
        const SizedBox(height: 10),
        for (final item in upcoming) ...[
          DeadlineCard(item: item, onTap: () => _openDetail(item)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _openAddDeadline() async {
    final item = await Navigator.of(context).push<DeadlineItem>(
      MaterialPageRoute(builder: (_) => const DeadlineFormPage()),
    );

    if (!mounted || item == null) {
      return;
    }

    setState(() => _items.add(item));
  }

  void _openDetail(DeadlineItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeadlineDetailPage(
          item: item,
          onChanged: _replaceItem,
          onDeleted: _deleteItem,
        ),
      ),
    );
  }

  void _replaceItem(DeadlineItem updated) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == updated.id);
      if (index != -1) {
        _items[index] = updated;
      }
    });
  }

  void _deleteItem(String id) {
    setState(() => _items.removeWhere((item) => item.id == id));
  }

  DateTime _weekStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - DateTime.monday));
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.unfinishedCount,
    required this.onAdd,
    required this.onClear,
    required this.onRestore,
  });

  final int unfinishedCount;
  final VoidCallback onAdd;
  final VoidCallback? onClear;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deadline',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$unfinishedCount deadline chưa hoàn thành',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Tùy chọn deadline',
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (value) {
            if (value == 'clear') {
              onClear?.call();
            }
            if (value == 'restore') {
              onRestore?.call();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clear',
              enabled: onClear != null,
              child: const Text('Xóa toàn bộ deadline mẫu'),
            ),
            PopupMenuItem(
              value: 'restore',
              enabled: onRestore != null,
              child: const Text('Khôi phục dữ liệu mẫu'),
            ),
          ],
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          tooltip: 'Thêm deadline',
          onPressed: onAdd,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF3478F6),
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

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({
    required this.controller,
    required this.priorityFilter,
    required this.onQueryChanged,
    required this.onPriorityChanged,
  });

  final TextEditingController controller;
  final DeadlinePriority? priorityFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<DeadlinePriority?> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF3478F6)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<DeadlinePriority?>(
          tooltip: 'Lọc deadline',
          onSelected: onPriorityChanged,
          itemBuilder: (context) => const [
            PopupMenuItem(value: null, child: Text('Tất cả')),
            PopupMenuItem(value: DeadlinePriority.low, child: Text('Thấp')),
            PopupMenuItem(
              value: DeadlinePriority.normal,
              child: Text('Bình thường'),
            ),
            PopupMenuItem(
              value: DeadlinePriority.urgent,
              child: Text('Khẩn cấp'),
            ),
          ],
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: priorityFilter == null
                  ? Colors.white
                  : const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EF)),
            ),
            child: const Icon(Icons.tune_rounded, color: Color(0xFF3478F6)),
          ),
        ),
      ],
    );
  }
}

class _ViewTabs extends StatelessWidget {
  const _ViewTabs({required this.value, required this.onChanged});

  final DeadlineView value;
  final ValueChanged<DeadlineView> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabChip(
            label: 'Tất cả',
            selected: value == DeadlineView.all,
            onTap: () => onChanged(DeadlineView.all),
          ),
          _TabChip(
            label: 'Hôm nay',
            selected: value == DeadlineView.today,
            onTap: () => onChanged(DeadlineView.today),
          ),
          _TabChip(
            label: 'Tuần',
            selected: value == DeadlineView.week,
            onTap: () => onChanged(DeadlineView.week),
          ),
          _TabChip(
            label: 'Quá hạn',
            selected: value == DeadlineView.overdue,
            onTap: () => onChanged(DeadlineView.overdue),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3478F6) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF3478F6)
                  : const Color(0xFFE5E7EF),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF667085),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class DeadlineCard extends StatelessWidget {
  const DeadlineCard({super.key, required this.item, required this.onTap});

  final DeadlineItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = item.isOverdue(demoNow);
    final badgeColor = overdue
        ? const Color(0xFFEF4444)
        : item.isDueToday(demoNow)
        ? const Color(0xFFFF8A00)
        : const Color(0xFF22C55E);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: overdue
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFE5E7EF),
            ),
            color: overdue ? const Color(0xFFFFF1F2) : Colors.white,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.assignment_rounded, color: item.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.subject,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.category,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    label: item.badgeText(demoNow),
                    color: badgeColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 15,
                    color: Color(0xFF667085),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    overdue
                        ? 'Quá hạn ${item.dueDateLabel}'
                        : item.dueTimeLabel(),
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item.progress} %',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: item.progress / 100,
                  backgroundColor: const Color(0xFFE5E7EF),
                  valueColor: AlwaysStoppedAnimation<Color>(item.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TodayView extends StatelessWidget {
  const _TodayView({required this.items, required this.onTap});

  final List<DeadlineItem> items;
  final ValueChanged<DeadlineItem> onTap;

  @override
  Widget build(BuildContext context) {
    final urgentCount = items
        .where((item) => item.priority == DeadlinePriority.urgent)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deadline hôm nay',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Ngày 9 tháng 4, 2026',
          style: TextStyle(
            color: Color(0xFF667085),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                value: '${items.length}',
                label: 'Cần làm',
                color: const Color(0xFFFF8A00),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                value: '$urgentCount',
                label: 'Khẩn cấp',
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final item in items) ...[
          DeadlineCard(item: item, onTap: () => onTap(item)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({required this.items, required this.onTap});

  final List<DeadlineItem> items;
  final ValueChanged<DeadlineItem> onTap;

  @override
  Widget build(BuildContext context) {
    final weekStart = DateTime(2026, 4, 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deadline tuần này',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        _WeekStrip(weekStart: weekStart, items: items),
        const SizedBox(height: 18),
        for (final item in items) ...[
          DeadlineCard(item: item, onTap: () => onTap(item)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OverdueView extends StatelessWidget {
  const _OverdueView({required this.items, required this.onTap});

  final List<DeadlineItem> items;
  final ValueChanged<DeadlineItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text(
              'Quá hạn',
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${items.length} deadline đã quá hạn',
          style: const TextStyle(
            color: Color(0xFF667085),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 22),
        for (final item in items) ...[
          DeadlineCard(item: item, onTap: () => onTap(item)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Text(
            'Những deadline quá hạn sẽ ảnh hưởng đến điểm số và tiến độ học tập của bạn. Hãy cố gắng hoàn thành chúng sớm nhất có thể.',
            style: TextStyle(
              color: Color(0xFFB42318),
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      height: 78,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.weekStart, required this.items});

  final DateTime weekStart;
  final List<DeadlineItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EF)),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final selected = date.day == demoNow.day;
          final hasDeadline = items.any(
            (item) =>
                item.dueDate.year == date.year &&
                item.dueDate.month == date.month &&
                item.dueDate.day == date.day,
          );

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF3478F6) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _weekdayLabel(date.weekday),
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF667085),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF101828),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasDeadline
                          ? (selected ? Colors.white : const Color(0xFF3478F6))
                          : Colors.transparent,
                      shape: BoxShape.circle,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onAdd,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 54),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF3478F6),
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 250,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
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
          Icon(icon, size: 42, color: const Color(0xFF3478F6)),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

String _weekdayLabel(int weekday) {
  const labels = <int, String>{
    DateTime.monday: 'T2',
    DateTime.tuesday: 'T3',
    DateTime.wednesday: 'T4',
    DateTime.thursday: 'T5',
    DateTime.friday: 'T6',
    DateTime.saturday: 'T7',
    DateTime.sunday: 'CN',
  };
  return labels[weekday] ?? 'T2';
}
