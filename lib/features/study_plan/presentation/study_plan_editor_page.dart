import 'package:flutter/material.dart';

import '../../../core/theme/studyflow_palette.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../subjects/data/subject_model.dart';
import '../data/study_plan_model.dart';

class StudyPlanEditorPage extends StatefulWidget {
  const StudyPlanEditorPage({
    super.key,
    required this.subjects,
    this.initialValue,
  });

  final List<SubjectModel> subjects;
  final StudyPlanModel? initialValue;

  @override
  State<StudyPlanEditorPage> createState() => _StudyPlanEditorPageState();
}

class _StudyPlanEditorPageState extends State<StudyPlanEditorPage> {
  static const List<String> _presetTopics = <String>[
    'User Research',
    'Wireframing',
    'Prototyping',
    'Usability Testing',
    'Design Systems',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  int? _subjectId;
  late DateTime _planDate;
  late TimeOfDay _startTime;
  late Set<String> _topics;

  bool get _isEditing => widget.initialValue != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialValue?.title ?? '');
    _subjectId = widget.initialValue?.subjectId;
    _planDate = widget.initialValue?.planDate ?? DateTime.now();
    _startTime = widget.initialValue?.startTime == null
        ? const TimeOfDay(hour: 14, minute: 0)
        : DateTimeUtils.parseTimeOfDay(widget.initialValue!.startTime!);
    _topics = (widget.initialValue?.topic ?? '')
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  SubjectModel? get _subject {
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
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: <Widget>[
              Text(
                'Chọn môn học',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ...widget.subjects.map((SubjectModel subject) {
                return ListTile(
                  onTap: () => Navigator.of(context).pop(subject.id),
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
    if (result == null) {
      return;
    }
    setState(() {
      _subjectId = result;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: _planDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (result != null) {
      setState(() {
        _planDate = result;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (result != null) {
      setState(() {
        _startTime = result;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final DateTime startDateTime = DateTime(
      _planDate.year,
      _planDate.month,
      _planDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final DateTime endDateTime = startDateTime.add(const Duration(hours: 2));
    Navigator.of(context).pop(
      StudyPlanModel(
        id: widget.initialValue?.id,
        subjectId: _subjectId,
        title: _titleController.text.trim(),
        planDate: _planDate,
        startTime: DateTimeUtils.formatTimeOfDay(_startTime),
        endTime:
            DateTimeUtils.formatTimeOfDay(TimeOfDay.fromDateTime(endDateTime)),
        duration: endDateTime.difference(startDateTime).inMinutes,
        topic: _topics.join(', '),
        status: widget.initialValue?.status ?? 'Planned',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SubjectModel? subject = _subject;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  children: <Widget>[
                    StudyFlowCircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Sửa kế hoạch' : 'Tạo kế hoạch',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  children: <Widget>[
                    const _EditorLabel(label: 'Tiêu đề'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _titleController,
                      decoration:
                          _fieldDecoration(hintText: 'VD: Ôn tập UX/UI Final'),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nhập tiêu đề kế hoạch.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const _EditorLabel(label: 'Môn học'),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickSubject,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: StudyFlowPalette.surfaceSoft,
                          borderRadius: BorderRadius.circular(20),
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
                              Expanded(
                                child: Text(
                                  subject.name,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ] else
                              const Expanded(
                                child: Text(
                                  'Chọn môn học',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const _EditorLabel(label: 'Ngày'),
                              const SizedBox(height: 10),
                              _TapField(
                                value: DateTimeUtils.toDbDate(_planDate),
                                onTap: _pickDate,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const _EditorLabel(label: 'Thời gian'),
                              const SizedBox(height: 10),
                              _TapField(
                                value:
                                    DateTimeUtils.formatTimeOfDay(_startTime),
                                onTap: _pickTime,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _EditorLabel(label: 'Chủ đề ôn tập'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _presetTopics.map((String topic) {
                        final bool selected = _topics.contains(topic);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _topics.remove(topic);
                              } else {
                                _topics.add(topic);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? StudyFlowPalette.blue
                                      .withValues(alpha: 0.10)
                                  : StudyFlowPalette.surfaceSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              topic,
                              style: TextStyle(
                                color: selected
                                    ? StudyFlowPalette.blue
                                    : const Color(0xFF475569),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: _isEditing
              ? Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: StudyFlowPalette.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              color: StudyFlowPalette.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StudyFlowGradientButton(
                        label: 'Lưu',
                        onTap: _submit,
                        height: 54,
                      ),
                    ),
                  ],
                )
              : StudyFlowGradientButton(
                  label: 'Tạo kế hoạch',
                  onTap: _submit,
                  height: 54,
                ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: StudyFlowPalette.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: StudyFlowPalette.blue),
      ),
    );
  }
}

class _EditorLabel extends StatelessWidget {
  const _EditorLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF334155),
            fontSize: 14,
          ),
    );
  }
}

class _TapField extends StatelessWidget {
  const _TapField({
    required this.value,
    required this.onTap,
  });

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: StudyFlowPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
