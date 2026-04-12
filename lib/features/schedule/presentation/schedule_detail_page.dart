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
    final ScheduleModel? schedule = await _scheduleRepository.getScheduleById(widget.scheduleId);
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
    final bool? changed = await context.push<bool>('/calendar/${widget.scheduleId}/edit');
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
      SnackBar(content: Text('Tính năng $label sẽ được triển khai ở phiên bản tới.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<_ScheduleDetailData?>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<_ScheduleDetailData?> snapshot) {
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
                      Text('Không tìm thấy lịch học', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      StudyFlowGradientButton(label: 'Quay lại', onTap: () => context.pop()),
                    ],
                  ),
                ),
              );
            }

            final ScheduleModel schedule = data.schedule;
            final SubjectModel? subject = data.subject;

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    StudyFlowCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    StudyFlowCircleIconButton(
                      icon: Icons.edit_outlined,
                      onTap: _openEdit,
                    ),
                    const SizedBox(width: 10),
                    StudyFlowCircleIconButton(
                      icon: Icons.delete_outline_rounded,
                      backgroundColor: const Color(0xFFFFF1F1),
                      foregroundColor: const Color(0xFFD9534F),
                      onTap: _deleteSchedule,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                StudyFlowIconBadge(
                  icon: Icons.menu_book_rounded,
                  backgroundColor: schedule.displayColor.withValues(alpha: 0.12),
                  foregroundColor: schedule.displayColor,
                  size: 64,
                  iconSize: 28,
                  borderRadius: 22,
                ),
                const SizedBox(height: 16),
                Text(
                  schedule.subjectName ?? subject?.name ?? 'Lịch học',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: StudyFlowPalette.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule.type,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: StudyFlowPalette.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                _ScheduleInfoCard(
                  icon: Icons.schedule_rounded,
                  title: 'Thời gian',
                  value: '${_weekdayLabel(schedule.weekday)} • ${schedule.timeRange}',
                ),
                const SizedBox(height: 12),
                _ScheduleInfoCard(
                  icon: Icons.location_on_outlined,
                  title: 'Địa điểm',
                  value: schedule.room.isEmpty ? 'Chưa có phòng học' : schedule.room,
                ),
                const SizedBox(height: 12),
                _ScheduleInfoCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Giảng viên',
                  value: subject?.teacher.isNotEmpty == true
                      ? subject!.teacher
                      : 'Chưa cập nhật giảng viên',
                ),
                if (subject != null) ...<Widget>[
                  const SizedBox(height: 18),
                  StudyFlowSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Thông tin môn học', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        if (subject.code.isNotEmpty)
                          Text('Mã môn: ${subject.code}', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Text('Số tín chỉ: ${subject.credits}', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StudyFlowOutlineButton(
                        label: 'Điểm danh',
                        icon: Icons.check_circle_outline_rounded,
                        onTap: () => _showPlaceholder('điểm danh'),
                        height: 54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StudyFlowGradientButton(
                        label: 'Nhắc nhở',
                        icon: Icons.notifications_none_rounded,
                        onTap: () => _showPlaceholder('nhắc nhở'),
                        height: 54,
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
}

class _ScheduleInfoCard extends StatelessWidget {
  const _ScheduleInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return StudyFlowSurfaceCard(
      child: Row(
        children: <Widget>[
          StudyFlowIconBadge(
            icon: icon,
            backgroundColor: StudyFlowPalette.surfaceSoft,
            foregroundColor: StudyFlowPalette.textSecondary,
            size: 40,
            iconSize: 18,
            borderRadius: 14,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
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

