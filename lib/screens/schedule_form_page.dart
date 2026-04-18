import 'package:flutter/material.dart';

import '../models/schedule_item.dart';

const _subjectOptions = [
  'UX/UI Design',
  'Web Development',
  'Database Systems',
  'English for IT',
  'HCI',
  'Mobile Programming',
];

const _colorOptions = [
  Color(0xFF7C5CFF),
  Color(0xFF21C26B),
  Color(0xFFFFB020),
  Color(0xFFFF6B6B),
  Color(0xFF3F6DF6),
];

class ScheduleFormPage extends StatefulWidget {
  const ScheduleFormPage({super.key, this.initialItem});

  final ScheduleItem? initialItem;

  @override
  State<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends State<ScheduleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomController;
  late final TextEditingController _instructorController;
  late String _title;
  late int _weekday;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late ClassMode _mode;
  late Color _color;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;

    _title = item?.title ?? _subjectOptions.first;
    _weekday = item?.weekday ?? DateTime.monday;
    _start = item?.start ?? const TimeOfDay(hour: 7, minute: 0);
    _end = item?.end ?? const TimeOfDay(hour: 9, minute: 30);
    _mode = item?.mode ?? ClassMode.theory;
    _color = item?.color ?? _colorOptions.first;
    _roomController = TextEditingController(text: item?.room ?? 'A301');
    _instructorController = TextEditingController(
      text: item?.instructor ?? 'Th.S Nguyễn Văn A',
    );
  }

  @override
  void dispose() {
    _roomController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

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
        title: Text(_isEditing ? 'Sửa lịch học' : 'Thêm lịch học'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
          children: [
            const _FieldLabel('Môn học'),
            DropdownButtonFormField<String>(
              initialValue: _title,
              decoration: _inputDecoration(
                icon: Icons.menu_book_outlined,
                hint: 'Chọn môn học',
              ),
              items: _subjectOptions
                  .map(
                    (subject) =>
                        DropdownMenuItem(value: subject, child: Text(subject)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _title = value);
                }
              },
            ),
            const SizedBox(height: 20),
            const _FieldLabel('Ngày trong tuần'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                final selected = _weekday == weekday;

                return ChoiceChip(
                  label: Text(compactWeekdayName(weekday)),
                  selected: selected,
                  onSelected: (_) => setState(() => _weekday = weekday),
                  selectedColor: const Color(0xFFEAF0FF),
                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFF315CE7)
                        : const Color(0xFF667085),
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF3F6DF6)
                          : const Color(0xFFE5E7EF),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Giờ bắt đầu',
                    value: _start,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _TimeField(
                    label: 'Giờ kết thúc',
                    value: _end,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _FieldLabel('Phòng học'),
            TextFormField(
              controller: _roomController,
              textCapitalization: TextCapitalization.characters,
              decoration: _inputDecoration(
                icon: Icons.location_on_outlined,
                hint: 'VD: A301',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập phòng học';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const _FieldLabel('Giảng viên'),
            TextFormField(
              controller: _instructorController,
              decoration: _inputDecoration(
                icon: Icons.person_outline_rounded,
                hint: 'VD: Th.S Nguyễn Văn A',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập giảng viên';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const _FieldLabel('Hình thức'),
            SegmentedButton<ClassMode>(
              segments: const [
                ButtonSegment(
                  value: ClassMode.theory,
                  icon: Icon(Icons.school_outlined),
                  label: Text('Lý thuyết'),
                ),
                ButtonSegment(
                  value: ClassMode.practice,
                  icon: Icon(Icons.computer_rounded),
                  label: Text('Thực hành'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) =>
                  setState(() => _mode = value.first),
            ),
            const SizedBox(height: 20),
            const _FieldLabel('Màu lịch'),
            Row(
              children: [
                for (final color in _colorOptions) ...[
                  _ColorSwatch(
                    color: color,
                    selected: color == _color,
                    onTap: () => setState(() => _color = color),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          22,
          16,
          22,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: FilledButton.icon(
          onPressed: _save,
          icon: Icon(_isEditing ? Icons.save_outlined : Icons.add_rounded),
          label: Text(_isEditing ? 'Lưu' : 'Thêm lịch học'),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required IconData icon,
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: Color(0xFF3F6DF6), width: 1.5),
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = ScheduleItem(
      id:
          widget.initialItem?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title,
      weekday: _weekday,
      start: _start,
      end: _end,
      room: _roomController.text.trim().toUpperCase(),
      instructor: _instructorController.text.trim(),
      mode: _mode,
      color: _color,
      attended: widget.initialItem?.attended ?? false,
      reminderEnabled: widget.initialItem?.reminderEnabled ?? false,
    );

    Navigator.of(context).pop(item);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF344054),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF667085)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatTimeOfDay(value),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF101828) : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white)
            : null,
      ),
    );
  }
}
