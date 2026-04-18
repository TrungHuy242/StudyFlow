import 'package:flutter/material.dart';

import '../../../../core/theme/studyflow_palette.dart';
import '../../../../shared/widgets/studyflow_components.dart';
import '../../data/notification_item_model.dart';

class NotificationFormResult {
  const NotificationFormResult._({
    this.item,
    required this.deleteRequested,
  });

  const NotificationFormResult.save(NotificationItemModel item)
      : this._(item: item, deleteRequested: false);

  const NotificationFormResult.delete()
      : this._(item: null, deleteRequested: true);

  final NotificationItemModel? item;
  final bool deleteRequested;
}

class NotificationFormSheet extends StatefulWidget {
  const NotificationFormSheet({
    super.key,
    this.initialValue,
  });

  final NotificationItemModel? initialValue;

  @override
  State<NotificationFormSheet> createState() => _NotificationFormSheetState();
}

class _NotificationFormSheetState extends State<NotificationFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late String _repeat;
  late bool _enabled;

  bool get _isEditing => widget.initialValue != null;

  @override
  void initState() {
    super.initState();
    final NotificationItemModel? initialValue = widget.initialValue;
    _titleController = TextEditingController(text: initialValue?.title ?? '');
    _repeat = _normalizeRepeat(initialValue?.type);
    _enabled = initialValue?.isEnabled ?? true;
    final DateTime? scheduledAt = initialValue?.scheduledAt;
    if (scheduledAt != null) {
      _selectedDate = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
      _selectedTime = TimeOfDay(hour: scheduledAt.hour, minute: scheduledAt.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _normalizeRepeat(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'daily':
      case 'hàng ngày':
      case 'study':
        return 'Hàng ngày';
      case 'weekly':
      case 'hàng tuần':
        return 'Hàng tuần';
      default:
        return 'Không lặp';
    }
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _selectedDate ?? now;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2035),
    );
    if (date == null) {
      return;
    }
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _selectedTime = time;
    });
  }

  DateTime? _scheduledAt() {
    if (_selectedDate == null || _selectedTime == null) {
      return null;
    }
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  String _dateLabel() {
    if (_selectedDate == null) {
      return 'dd/mm/yyyy';
    }
    final String day = _selectedDate!.day.toString().padLeft(2, '0');
    final String month = _selectedDate!.month.toString().padLeft(2, '0');
    return '$day/$month/${_selectedDate!.year}';
  }

  String _timeLabel() {
    if (_selectedTime == null) {
      return '--:--';
    }
    final String hour = _selectedTime!.hour.toString().padLeft(2, '0');
    final String minute = _selectedTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final NotificationItemModel item = NotificationItemModel(
      id: widget.initialValue?.id,
      type: _repeat,
      title: _titleController.text.trim(),
      message: _titleController.text.trim(),
      scheduledAt: _scheduledAt(),
      isRead: _enabled,
      relatedId: widget.initialValue?.relatedId,
    );
    Navigator.of(context).pop(NotificationFormResult.save(item));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: <Widget>[
              Row(
                children: <Widget>[
                  StudyFlowCircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Sửa nhắc nhở' : 'Thêm nhắc nhở',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Tiêu đề',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: _fieldDecoration(hintText: 'VD: Học bài Toán...'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tiêu đề nhắc nhở.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ReminderPickerField(
                      label: 'Ngày',
                      value: _dateLabel(),
                      icon: Icons.calendar_month_rounded,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ReminderPickerField(
                      label: 'Giờ',
                      value: _timeLabel(),
                      icon: Icons.schedule_rounded,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Lặp lại',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _repeat,
                decoration: _fieldDecoration(),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'Không lặp',
                    child: Text('Không lặp'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Hàng ngày',
                    child: Text('Hàng ngày'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Hàng tuần',
                    child: Text('Hàng tuần'),
                  ),
                ],
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _repeat = value;
                  });
                },
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: StudyFlowPalette.border),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Bật thông báo',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF1E293B),
                              fontSize: 14,
                            ),
                      ),
                    ),
                    ReminderToggle(
                      value: _enabled,
                      onChanged: (bool value) {
                        setState(() {
                          _enabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: _isEditing
              ? Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(const NotificationFormResult.delete());
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF4C7C7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Xóa',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StudyFlowGradientButton(
                        label: 'Lưu thay đổi',
                        onTap: _submit,
                        height: 52,
                      ),
                    ),
                  ],
                )
              : StudyFlowGradientButton(
                  label: 'Lưu nhắc nhở',
                  onTap: _submit,
                  height: 52,
                ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: StudyFlowPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: StudyFlowPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: StudyFlowPalette.blue),
      ),
    );
  }
}

class _ReminderPickerField extends StatelessWidget {
  const _ReminderPickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: StudyFlowPalette.border),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                  ),
                ),
                Icon(icon, color: const Color(0xFF64748B), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ReminderToggle extends StatelessWidget {
  const ReminderToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
