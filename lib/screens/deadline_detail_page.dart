import 'package:flutter/material.dart';

import '../data/sample_deadlines.dart';
import '../models/deadline_item.dart';
import 'deadline_form_page.dart';

class DeadlineDetailPage extends StatefulWidget {
  const DeadlineDetailPage({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDeleted,
  });

  final DeadlineItem item;
  final ValueChanged<DeadlineItem> onChanged;
  final ValueChanged<String> onDeleted;

  @override
  State<DeadlineDetailPage> createState() => _DeadlineDetailPageState();
}

class _DeadlineDetailPageState extends State<DeadlineDetailPage> {
  late DeadlineItem _item = widget.item;

  @override
  Widget build(BuildContext context) {
    final overdue = _item.isOverdue(demoNow);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Sửa deadline',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEdit,
          ),
          IconButton(
            tooltip: 'Xóa deadline',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        children: [
          _HeaderCard(item: _item),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _toggleComplete,
                  icon: Icon(
                    _item.completed
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                  ),
                  label: Text(_item.completed ? 'Hoàn thành' : 'Chưa xong'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: const Color(0xFF3478F6),
                    side: const BorderSide(color: Color(0xFFD6E4FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _item.completed ? null : _increaseProgress,
                  icon: const Icon(Icons.trending_up_rounded),
                  label: const Text('Hoàn tất +10%'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoTile(
            icon: Icons.calendar_today_outlined,
            title: 'Ngày đến hạn',
            value: _item.dueDateLabel,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.access_time_rounded,
            title: 'Giờ đến hạn',
            value: _item.dueTimeLabel(),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.flag_outlined,
            title: 'Mức độ ưu tiên',
            value: _item.priorityLabel,
          ),
          const SizedBox(height: 18),
          _ProgressPanel(item: _item),
          const SizedBox(height: 18),
          if (_item.description.isNotEmpty)
            _DescriptionPanel(description: _item.description),
          if (overdue) ...[const SizedBox(height: 18), const _WarningPanel()],
        ],
      ),
    );
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<DeadlineItem>(
      MaterialPageRoute(builder: (_) => DeadlineFormPage(initialItem: _item)),
    );

    if (!mounted || updated == null) {
      return;
    }

    setState(() => _item = updated);
    widget.onChanged(updated);
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa deadline?'),
        content: Text('Bạn có chắc muốn xóa "${_item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    widget.onDeleted(_item.id);
    Navigator.of(context).pop();
  }

  void _toggleComplete() {
    final updated = _item.copyWith(
      completed: !_item.completed,
      progress: _item.completed ? _item.progress : 100,
    );
    setState(() => _item = updated);
    widget.onChanged(updated);
  }

  void _increaseProgress() {
    final nextProgress = (_item.progress + 10).clamp(0, 100);
    final updated = _item.copyWith(
      progress: nextProgress,
      completed: nextProgress == 100,
    );
    setState(() => _item = updated);
    widget.onChanged(updated);
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.item});

  final DeadlineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.assignment_rounded, color: item.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 17,
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
                const SizedBox(height: 12),
                _Badge(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.item});

  final DeadlineItem item;

  @override
  Widget build(BuildContext context) {
    final overdue = item.isOverdue(demoNow);
    final color = overdue ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        item.badgeText(demoNow),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF3478F6)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.item});

  final DeadlineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tiến độ',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${item.progress} %',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: item.progress / 100,
              backgroundColor: const Color(0xFFE5E7EF),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionPanel extends StatelessWidget {
  const _DescriptionPanel({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(
              color: Color(0xFF101828),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF667085),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningPanel extends StatelessWidget {
  const _WarningPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Text(
        'Deadline quá hạn có thể ảnh hưởng đến điểm số và tiến độ học tập. Hãy hoàn thành sớm nhất có thể.',
        style: TextStyle(
          color: Color(0xFFB42318),
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
