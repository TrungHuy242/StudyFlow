import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../subjects/data/subject_model.dart';
import '../../subjects/data/subject_repository.dart';
import '../data/schedule_model.dart';
import '../data/schedule_repository.dart';

class ScheduleEditorPage extends StatefulWidget {
  const ScheduleEditorPage({
    super.key,
    this.scheduleId,
  });

  final int? scheduleId;

  @override
  State<ScheduleEditorPage> createState() => _ScheduleEditorPageState();
}

class _ScheduleEditorPageState extends State<ScheduleEditorPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _roomController = TextEditingController();
  late final SubjectRepository _subjectRepository;
  late final ScheduleRepository _scheduleRepository;
  late Future<_ScheduleEditorData> _future;
  bool _initialized = false;
  bool _saving = false;

  int? _selectedSubjectId;
  int _selectedWeekday = DateTime.now().weekday;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 30);
  String _type = 'Lý thuyết';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final DatabaseService databaseService = context.read<DatabaseService>();
    _subjectRepository = SubjectRepository(databaseService);
    _scheduleRepository = ScheduleRepository(databaseService);
    _future = _loadData();
    _initialized = true;
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<_ScheduleEditorData> _loadData() async {
    final List<SubjectModel> subjects = await _subjectRepository.getSubjects();
    final ScheduleModel? schedule = widget.scheduleId == null
        ? null
        : await _scheduleRepository.getScheduleById(widget.scheduleId!);

    if (schedule != null) {
      _selectedSubjectId = schedule.subjectId;
      _selectedWeekday = schedule.weekday;
      _startTime = DateTimeUtils.parseTimeOfDay(schedule.startTime);
      _endTime = DateTimeUtils.parseTimeOfDay(schedule.endTime);
      _roomController.text = schedule.room;
      _type = schedule.type;
    } else if (subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    return _ScheduleEditorData(subjects: subjects, schedule: schedule);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay? value = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (value == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  Future<void> _submit(_ScheduleEditorData data) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn môn học.')),
      );
      return;
    }

    final int startMinutes = (_startTime.hour * 60) + _startTime.minute;
    final int endMinutes = (_endTime.hour * 60) + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    await _scheduleRepository.saveSchedule(
      ScheduleModel(
        id: data.schedule?.id,
        subjectId: _selectedSubjectId!,
        weekday: _selectedWeekday,
        startTime: DateTimeUtils.formatTimeOfDay(_startTime),
        endTime: DateTimeUtils.formatTimeOfDay(_endTime),
        room: _roomController.text.trim(),
        type: _type,
      ),
    );

    if (!mounted) {
      return;
    }
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: FutureBuilder<_ScheduleEditorData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_ScheduleEditorData> snapshot) {
          final _ScheduleEditorData? data = snapshot.data;
          if (data == null || data.subjects.isEmpty) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              child: StudyFlowGradientButton(
                label: widget.scheduleId == null ? 'Thêm lịch học' : 'Cập nhật lịch học',
                icon: Icons.add_rounded,
                onTap: _saving ? null : () => _submit(data),
              ),
            ),
          );
        },
      ),
      body: SafeArea(
        child: FutureBuilder<_ScheduleEditorData>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<_ScheduleEditorData> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final _ScheduleEditorData data = snapshot.data ?? const _ScheduleEditorData();
            if (data.subjects.isEmpty) {
              return _ScheduleMissingSubjects(
                onBack: () => context.pop(),
                onCreateSubject: () => context.push('/subjects/add'),
              );
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      StudyFlowCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          widget.scheduleId == null ? 'Thêm lịch học' : 'Sửa lịch học',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text('Môn học', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedSubjectId,
                    icon: const Icon(Icons.expand_more_rounded, color: StudyFlowPalette.textMuted),
                    decoration: _fieldDecoration(),
                    items: data.subjects
                        .where((SubjectModel subject) => subject.id != null)
                        .map((SubjectModel subject) {
                      return DropdownMenuItem<int>(
                        value: subject.id,
                        child: Text(subject.name),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() {
                        _selectedSubjectId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Ngày trong tuần', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<Widget>.generate(7, (int index) {
                      final int weekday = index + 1;
                      final bool selected = _selectedWeekday == weekday;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWeekday = weekday;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 40,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected ? StudyFlowPalette.blue : StudyFlowPalette.surfaceSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _weekdayChip(weekday),
                            style: TextStyle(
                              color: selected ? Colors.white : StudyFlowPalette.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _TimeField(
                          label: 'Giờ bắt đầu',
                          value: DateTimeUtils.formatTimeOfDay(_startTime),
                          onTap: () => _pickTime(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TimeField(
                          label: 'Giờ kết thúc',
                          value: DateTimeUtils.formatTimeOfDay(_endTime),
                          onTap: () => _pickTime(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  StudyFlowInput(
                    controller: _roomController,
                    label: 'Phòng học',
                    hintText: 'VD: A301',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 20),
                  Text('Hình thức', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      for (final String option in const <String>['Lý thuyết', 'Thực hành', 'Seminar'])
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = option;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _type == option
                                  ? StudyFlowPalette.blue.withValues(alpha: 0.12)
                                  : StudyFlowPalette.surfaceSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _type == option
                                    ? StudyFlowPalette.blue
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                color: _type == option
                                    ? StudyFlowPalette.blue
                                    : StudyFlowPalette.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: StudyFlowPalette.surfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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

  String _weekdayChip(int weekday) {
    const List<String> labels = <String>['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return labels[weekday - 1];
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: StudyFlowPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.schedule_rounded, size: 18, color: StudyFlowPalette.textMuted),
                const SizedBox(width: 10),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleMissingSubjects extends StatelessWidget {
  const _ScheduleMissingSubjects({
    required this.onBack,
    required this.onCreateSubject,
  });

  final VoidCallback onBack;
  final VoidCallback onCreateSubject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StudyFlowCircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const Spacer(),
          const Center(
            child: StudyFlowIconBadge(
              icon: Icons.menu_book_rounded,
              backgroundColor: Color(0xFFF0F5FD),
              foregroundColor: Color(0xFFAABBD2),
              size: 80,
              iconSize: 34,
              borderRadius: 26,
            ),
          ),
          const SizedBox(height: 20),
          Center(child: Text('Chưa có môn học', style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Tạo ít nhất một môn học trước khi thêm lịch học.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          StudyFlowGradientButton(label: 'Thêm môn học', onTap: onCreateSubject),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ScheduleEditorData {
  const _ScheduleEditorData({
    this.subjects = const <SubjectModel>[],
    this.schedule,
  });

  final List<SubjectModel> subjects;
  final ScheduleModel? schedule;
}
