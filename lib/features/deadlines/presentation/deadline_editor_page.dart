import 'package:flutter/material.dart';

import '../../../core/theme/studyflow_palette.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../subjects/data/subject_model.dart';
import '../data/deadline_model.dart';

class DeadlineEditorPage extends StatefulWidget {
  const DeadlineEditorPage({
    super.key,
    required this.subjects,
    this.initialValue,
  });

  final List<SubjectModel> subjects;
  final DeadlineModel? initialValue;

  @override
  State<DeadlineEditorPage> createState() => _DeadlineEditorPageState();
}

class _DeadlineEditorPageState extends State<DeadlineEditorPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  int? _subjectId;
  late DateTime _dueDate;
  TimeOfDay _dueTime = const TimeOfDay(hour: 23, minute: 59);
  late String _priority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialValue?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initialValue?.description ?? '');
    _subjectId = widget.initialValue?.subjectId;
    _dueDate = widget.initialValue?.dueDate ?? DateTime.now().add(const Duration(days: 2));
    _priority = widget.initialValue?.priority ?? 'Medium';
    final TimeOfDay? parsedTime = widget.initialValue?.dueTime == null
        ? null
        : DateTimeUtils.parseTimeOfDay(widget.initialValue!.dueTime!);
    if (parsedTime != null) {
      _dueTime = parsedTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  SubjectModel? get _selectedSubject {
    for (final SubjectModel subject in widget.subjects) {
      if (subject.id == _subjectId) {
        return subject;
      }
    }
    return null;
  }

  Future<void> _pickSubject() async {
    if (widget.subjects.isEmpty) {
      return;
    }
    final int? result = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: <Widget>[
              Text(
                'Chọn môn học',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ListTile(
                onTap: () => Navigator.of(context).pop(null),
                contentPadding: EdgeInsets.zero,
                title: const Text('Không gắn môn học'),
              ),
              ...widget.subjects.map((SubjectModel subject) {
                return ListTile(
                  onTap: () => Navigator.of(context).pop(subject.id),
                  contentPadding: EdgeInsets.zero,
                  leading: StudyFlowIconBadge(
                    icon: Icons.menu_book_rounded,
                    backgroundColor: subject.displayColor,
                    size: 36,
                    iconSize: 16,
                    borderRadius: 12,
                  ),
                  title: Text(subject.name),
                  subtitle: Text(subject.code),
                );
              }),
            ],
          ),
        );
      },
    );
    if (result == _subjectId || !mounted) {
      return;
    }
    setState(() {
      _subjectId = result;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (result == null) {
      return;
    }
    setState(() {
      _dueDate = result;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (result == null) {
      return;
    }
    setState(() {
      _dueTime = result;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      DeadlineModel(
        id: widget.initialValue?.id,
        subjectId: _subjectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        dueTime: DateTimeUtils.formatTimeOfDay(_dueTime),
        priority: _priority,
        status: widget.initialValue?.status ?? 'Planned',
        progress: widget.initialValue?.progress ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.initialValue != null;
    final SubjectModel? subject = _selectedSubject;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Row(
                  children: <Widget>[
                    StudyFlowCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        isEditing ? 'Sửa Deadline' : 'Thêm Deadline',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 34, 22, 24),
                  children: <Widget>[
                    StudyFlowInput(
                      controller: _titleController,
                      label: 'Tiêu đề',
                      hintText: 'VD: Assignment 1 - UX Research',
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nhập tiêu đề deadline.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel(
                      label: 'Môn học',
                      child: InkWell(
                        onTap: _pickSubject,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: StudyFlowPalette.surfaceSoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: <Widget>[
                              if (subject != null) ...<Widget>[
                                StudyFlowIconBadge(
                                  icon: Icons.menu_book_rounded,
                                  backgroundColor: subject.displayColor,
                                  size: 28,
                                  iconSize: 14,
                                  borderRadius: 10,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(subject.name)),
                              ] else
                                const Expanded(
                                  child: Text(
                                    'Chọn môn học',
                                    style: TextStyle(color: StudyFlowPalette.textMuted),
                                  ),
                                ),
                              const Icon(Icons.keyboard_arrow_down_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel(
                      label: 'Ngày đến hạn',
                      child: _ReadonlyField(
                        value: DateTimeUtils.toDbDate(_dueDate),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel(
                      label: 'Giờ đến hạn',
                      child: _ReadonlyField(
                        value: DateTimeUtils.formatTimeOfDay(_dueTime),
                        onTap: _pickTime,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Mức độ ưu tiên',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _PriorityChip(
                            label: 'Thấp',
                            color: const Color(0xFF94A3B8),
                            selected: _priority == 'Low',
                            onTap: () => setState(() => _priority = 'Low'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PriorityChip(
                            label: 'Bình thường',
                            color: StudyFlowPalette.orange,
                            selected: _priority == 'Medium',
                            onTap: () => setState(() => _priority = 'Medium'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PriorityChip(
                            label: 'Khẩn cấp',
                            color: StudyFlowPalette.coral,
                            selected: _priority == 'High',
                            onTap: () => setState(() => _priority = 'High'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    StudyFlowInput(
                      controller: _descriptionController,
                      label: 'Mô tả (tùy chọn)',
                      hintText: 'Ghi chú thêm cho deadline này',
                      maxLines: 6,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: StudyFlowPalette.border),
                  ),
                ),
                child: isEditing
                    ? Row(
                        children: <Widget>[
                          Expanded(
                            child: StudyFlowOutlineButton(
                              label: 'Hủy',
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StudyFlowGradientButton(
                              label: 'Lưu',
                              onTap: _submit,
                              height: 52,
                            ),
                          ),
                        ],
                      )
                    : StudyFlowGradientButton(
                        label: '+ Thêm Deadline',
                        onTap: _submit,
                        height: 60,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.value,
    required this.onTap,
  });

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: StudyFlowPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Text(value),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : StudyFlowPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.7) : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : StudyFlowPalette.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
