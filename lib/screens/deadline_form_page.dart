import 'package:flutter/material.dart';

import '../models/deadline_item.dart';

const _subjects = [
  'UX/UI Design',
  'Web Development',
  'Database Systems',
  'English for IT',
  'HCI',
];

const _categories = ['Research', 'Quiz', 'Design', 'Writing', 'Review', 'Lab'];

const _colors = [
  Color(0xFF6366F1),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
  Color(0xFFEF4444),
];

class DeadlineFormPage extends StatefulWidget {
  const DeadlineFormPage({super.key, this.initialItem});

  final DeadlineItem? initialItem;

  @override
  State<DeadlineFormPage> createState() => _DeadlineFormPageState();
}

class _DeadlineFormPageState extends State<DeadlineFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _subject;
  late String _category;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late DeadlinePriority _priority;
  late int _progress;
  late Color _color;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _titleController = TextEditingController(
      text: item?.title ?? 'Assignment 1 - UX Research',
    );
    _descriptionController = TextEditingController(text: item?.description);
    _subject = item?.subject ?? _subjects.first;
    _category = item?.category ?? _categories.first;
    _dueDate = item?.dueDate ?? DateTime(2026, 4, 12);
    _dueTime = item?.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    _priority = item?.priority ?? DeadlinePriority.normal;
    _progress = item?.progress ?? 0;
    _color = item?.color ?? _colors.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
        title: Text(_isEditing ? 'Sửa Deadline' : 'Thêm Deadline'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 128),
          children: [
            const _FieldLabel('Tiêu đề'),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(
                icon: Icons.assignment_outlined,
                hint: 'VD: Assignment 1 - UX Research',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Môn học'),
            DropdownButtonFormField<String>(
              initialValue: _subject,
              decoration: _inputDecoration(
                icon: Icons.menu_book_outlined,
                hint: 'Chọn môn học',
              ),
              items: _subjects
                  .map(
                    (subject) =>
                        DropdownMenuItem(value: subject, child: Text(subject)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _subject = value);
                }
              },
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Loại nhiệm vụ'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _inputDecoration(
                icon: Icons.category_outlined,
                hint: 'Chọn loại',
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 18),
            _PickerField(
              label: 'Ngày đến hạn',
              icon: Icons.calendar_today_outlined,
              value:
                  '${_dueDate.year}-${_two(_dueDate.month)}-${_two(_dueDate.day)}',
              onTap: _pickDate,
            ),
            const SizedBox(height: 18),
            _PickerField(
              label: 'Giờ đến hạn',
              icon: Icons.access_time_rounded,
              value: '${_two(_dueTime.hour)}:${_two(_dueTime.minute)}',
              onTap: _pickTime,
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Mức độ ưu tiên'),
            Row(
              children: [
                Expanded(
                  child: _PriorityButton(
                    label: 'Thấp',
                    selected: _priority == DeadlinePriority.low,
                    onTap: () =>
                        setState(() => _priority = DeadlinePriority.low),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriorityButton(
                    label: 'Bình thường',
                    selected: _priority == DeadlinePriority.normal,
                    onTap: () =>
                        setState(() => _priority = DeadlinePriority.normal),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriorityButton(
                    label: 'Khẩn cấp',
                    selected: _priority == DeadlinePriority.urgent,
                    onTap: () =>
                        setState(() => _priority = DeadlinePriority.urgent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: _FieldLabel('Tiến độ')),
                Text(
                  '$_progress %',
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Slider(
              value: _progress.toDouble(),
              max: 100,
              divisions: 20,
              label: '$_progress%',
              onChanged: (value) => setState(() => _progress = value.round()),
            ),
            const SizedBox(height: 8),
            const _FieldLabel('Màu'),
            Row(
              children: [
                for (final color in _colors) ...[
                  _ColorSwatch(
                    color: color,
                    selected: color == _color,
                    onTap: () => setState(() => _color = color),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Mô tả (tùy chọn)'),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 5,
              decoration: _inputDecoration(
                icon: Icons.notes_rounded,
                hint: 'Mô tả chi tiết deadline...',
              ),
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
        child: _isEditing
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              )
            : FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm Deadline'),
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
        borderSide: const BorderSide(color: Color(0xFF3478F6), width: 1.5),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );

    if (!mounted || picked == null) {
      return;
    }
    setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
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
    setState(() => _dueTime = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = DeadlineItem(
      id:
          widget.initialItem?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      subject: _subject,
      category: _category,
      dueDate: _dueDate,
      dueTime: _dueTime,
      priority: _priority,
      progress: _progress,
      color: _color,
      description: _descriptionController.text.trim(),
      completed: widget.initialItem?.completed ?? false,
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

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
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
                Icon(icon, color: const Color(0xFF667085)),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
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

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0C7) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EF),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? const Color(0xFFB45309) : const Color(0xFF667085),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
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
        width: 40,
        height: 40,
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

String _two(int value) => value.toString().padLeft(2, '0');
