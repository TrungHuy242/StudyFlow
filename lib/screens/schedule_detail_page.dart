import 'package:flutter/material.dart';

import '../models/schedule_item.dart';
import 'schedule_form_page.dart';

class ScheduleDetailPage extends StatefulWidget {
  const ScheduleDetailPage({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDeleted,
  });

  final ScheduleItem item;
  final ValueChanged<ScheduleItem> onChanged;
  final ValueChanged<String> onDeleted;

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late ScheduleItem _item = widget.item;

  @override
  Widget build(BuildContext context) {
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
            tooltip: 'Sửa lịch học',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEdit,
          ),
          IconButton(
            tooltip: 'Xóa lịch học',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        children: [
          _HeroPanel(item: _item),
          const SizedBox(height: 18),
          _InfoTile(
            icon: Icons.schedule_rounded,
            title: 'Thời gian',
            value: _item.timeRange(context),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.location_on_outlined,
            title: 'Địa điểm',
            value: _item.room,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.person_outline_rounded,
            title: 'Giảng viên',
            value: _item.instructor,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _toggleAttendance,
                  icon: Icon(
                    _item.attended
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                  ),
                  label: Text(_item.attended ? 'Đã có mặt' : 'Đánh dấu có mặt'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: const Color(0xFF315CE7),
                    side: const BorderSide(color: Color(0xFFD6E0FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _toggleReminder,
                  icon: Icon(
                    _item.reminderEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                  ),
                  label: Text(
                    _item.reminderEnabled ? 'Đã nhắc' : 'Thêm nhắc nhở',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<ScheduleItem>(
      MaterialPageRoute(builder: (_) => ScheduleFormPage(initialItem: _item)),
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
        title: const Text('Xóa lịch học?'),
        content: Text('Bạn có chắc muốn xóa ${_item.title}?'),
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

  void _toggleAttendance() {
    final updated = _item.copyWith(attended: !_item.attended);
    setState(() => _item = updated);
    widget.onChanged(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.attended
              ? 'Đã đánh dấu có mặt cho ${updated.title}.'
              : 'Đã bỏ đánh dấu có mặt.',
        ),
      ),
    );
  }

  void _toggleReminder() {
    final updated = _item.copyWith(reminderEnabled: !_item.reminderEnabled);
    setState(() => _item = updated);
    widget.onChanged(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.reminderEnabled
              ? 'Đã bật nhắc nhở trước giờ học.'
              : 'Đã tắt nhắc nhở.',
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [item.color, const Color(0xFF3F6DF6)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.weekdayLabel} • ${item.modeLabel}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF315CE7)),
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
