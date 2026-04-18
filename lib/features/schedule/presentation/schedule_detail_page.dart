import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../subjects/data/subject_model.dart';
import '../../subjects/data/subject_repository.dart';
import '../data/schedule_model.dart';
import '../data/schedule_repository.dart';

class ScheduleDetailPage extends StatefulWidget {
  const ScheduleDetailPage({
    super.key,
    required this.scheduleId,
  });

  final int scheduleId;

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late final ScheduleRepository _scheduleRepository;
  late final SubjectRepository _subjectRepository;
  late Future<_ScheduleDetailData?> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final DatabaseService databaseService = context.read<DatabaseService>();
    _scheduleRepository = ScheduleRepository(databaseService);
    _subjectRepository = SubjectRepository(databaseService);
    _future = _loadData();
    _initialized = true;
  }

  Future<_ScheduleDetailData?> _loadData() async {
    final ScheduleModel? schedule =
        await _scheduleRepository.getScheduleById(widget.scheduleId);
    if (schedule == null) {
      return null;
    }

    final List<SubjectModel> subjects = await _subjectRepository.getSubjects();
    SubjectModel? subject;
    for (final SubjectModel item in subjects) {
      if (item.id == schedule.subjectId) {
        subject = item;
        break;
      }
    }

    return _ScheduleDetailData(schedule: schedule, subject: subject);
  }

  Future<void> _openEdit() async {
    final bool? changed =
        await context.push<bool>('/calendar/${widget.scheduleId}/edit');
    if (changed != true) {
      return;
    }
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _deleteSchedule() async {
    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Xóa lịch học?',
      message: 'Buổi học này sẽ bị xóa khỏi thời khóa biểu của bạn.',
      confirmLabel: 'Xóa',
      cancelLabel: 'Hủy',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    await _scheduleRepository.deleteSchedule(widget.scheduleId);
    if (!mounted) {
      return;
    }
    context.pop(true);
  }

  void _showPlaceholder(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Tính năng $label sẽ được triển khai ở phiên bản tới.')),
    );
  }

  String _weekdayLabel(int weekday) {
    const List<String> labels = <String>[
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    return labels[weekday - 1];
  }

  String _displayType(String value) {
    switch (value.toLowerCase()) {
      case 'lecture':
      case 'lý thuyết':
        return 'Lý thuyết';
      case 'practice':
      case 'thực hành':
        return 'Thực hành';
      case 'seminar':
        return 'Seminar';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<_ScheduleDetailData?>(
          future: _future,
          builder: (BuildContext context,
              AsyncSnapshot<_ScheduleDetailData?> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final _ScheduleDetailData? data = snapshot.data;
            if (data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Không tìm thấy lịch học',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      StudyFlowGradientButton(
                        label: 'Quay lại',
                        onTap: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              );
            }

            final ScheduleModel schedule = data.schedule;
            final SubjectModel? subject = data.subject;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    StudyFlowCircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    StudyFlowCircleIconButton(
                      icon: Icons.edit_outlined,
                      size: 42,
                      onTap: _openEdit,
                    ),
                    const SizedBox(width: 10),
                    StudyFlowCircleIconButton(
                      icon: Icons.delete_outline_rounded,
                      size: 42,
                      backgroundColor: const Color(0xFFFFF1EE),
                      foregroundColor: StudyFlowPalette.red,
                      onTap: _deleteSchedule,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  decoration: BoxDecoration(
                    color: schedule.displayColor,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        schedule.subjectName ?? subject?.name ?? 'Lịch học',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _displayType(schedule.type),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 16,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _ScheduleInfoSection(
                  label: 'Thời gian',
                  value:
                      '${_weekdayLabel(schedule.weekday)} • ${schedule.timeRange}',
                ),
                const SizedBox(height: 18),
                _ScheduleInfoSection(
                  label: 'Địa điểm',
                  value: schedule.room.isEmpty
                      ? 'Chưa có phòng học'
                      : schedule.room,
                ),
                const SizedBox(height: 18),
                _ScheduleInfoSection(
                  label: 'Giảng viên',
                  value: subject?.teacher.isNotEmpty == true
                      ? subject!.teacher
                      : 'Chưa cập nhật giảng viên',
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ActionTextButton(
                        label: 'Đánh dấu có mặt',
                        active: true,
                        onTap: () => _showPlaceholder('điểm danh'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionTextButton(
                        label: 'Thêm nhắc nhở',
                        active: false,
                        onTap: () => _showPlaceholder('nhắc nhở'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScheduleInfoSection extends StatelessWidget {
  const _ScheduleInfoSection({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionTextButton extends StatelessWidget {
  const _ActionTextButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color:
              active ? const Color(0xFFEFF6FF) : StudyFlowPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? StudyFlowPalette.blue : const Color(0xFF475569),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ScheduleDetailData {
  const _ScheduleDetailData({
    required this.schedule,
    required this.subject,
  });

  final ScheduleModel schedule;
  final SubjectModel? subject;
}
