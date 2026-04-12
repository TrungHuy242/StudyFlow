// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../deadlines/data/deadline_model.dart';
import '../../deadlines/data/deadline_repository.dart';
import '../../schedule/data/schedule_model.dart';
import '../../schedule/data/schedule_repository.dart';
import '../data/subject_model.dart';
import '../data/subject_repository.dart';

class SubjectDetailPage extends StatefulWidget {
  const SubjectDetailPage({
    super.key,
    required this.subjectId,
  });

  final int subjectId;

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  late final SubjectRepository _subjectRepository;
  late final ScheduleRepository _scheduleRepository;
  late final DeadlineRepository _deadlineRepository;
  late Future<_SubjectDetailData?> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final DatabaseService databaseService = context.read<DatabaseService>();
    _subjectRepository = SubjectRepository(databaseService);
    _scheduleRepository = ScheduleRepository(databaseService);
    _deadlineRepository = DeadlineRepository(databaseService);
    _future = _load();
    _initialized = true;
  }

  Future<_SubjectDetailData?> _load() async {
    final SubjectModel? subject = await _subjectRepository.getSubjectById(widget.subjectId);
    if (subject == null) return null;
    final List<ScheduleModel> schedules = await _scheduleRepository.getSchedules();
    final List<DeadlineModel> deadlines = await _deadlineRepository.getDeadlines();
    final List<ScheduleModel> subjectSchedules =
        schedules.where((ScheduleModel item) => item.subjectId == widget.subjectId).toList();
    final List<DeadlineModel> subjectDeadlines =
        deadlines.where((DeadlineModel item) => item.subjectId == widget.subjectId).toList();
    final int progress = subjectDeadlines.isEmpty
        ? 0
        : subjectDeadlines.fold<int>(0, (int sum, DeadlineModel item) => sum + item.progress) ~/
            subjectDeadlines.length;
    return _SubjectDetailData(
      subject: subject,
      schedule: subjectSchedules.isEmpty ? null : subjectSchedules.first,
      progress: progress,
    );
  }

  Future<void> _delete(SubjectModel subject) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa môn học?'),
          content: Text('Môn "${subject.name}" sẽ bị xóa khỏi thiết bị.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
          ],
        );
      },
    );
    if (confirm != true) return;
    await _subjectRepository.deleteSubject(subject.id!);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<_SubjectDetailData?>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_SubjectDetailData?> snapshot) {
          final _SubjectDetailData? data = snapshot.data;
          final SubjectModel? subject = data?.subject;
          if (subject == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
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
                      onTap: () async {
                        await context.push('/subjects/${subject.id}/edit');
                        setState(() {
                          _future = _load();
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    StudyFlowCircleIconButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: () => _delete(subject),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[subject.displayColor, subject.displayColor.withValues(alpha: 0.78)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      StudyFlowIconBadge(
                        icon: Icons.menu_book_rounded,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        size: 64,
                        iconSize: 28,
                      ),
                      const SizedBox(height: 16),
                      Text(subject.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${subject.code} • ${subject.credits} tín chỉ',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                StudyFlowSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Expanded(child: Text('Tiến độ học tập')),
                          Text('${data!.progress} %'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StudyFlowProgressBar(
                        value: data.progress / 100,
                        color: subject.displayColor,
                        height: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _InfoTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Giảng viên',
                  value: subject.teacher.isEmpty ? 'Chưa cập nhật' : subject.teacher,
                ),
                const SizedBox(height: 12),
                _InfoTile(
                  icon: Icons.schedule_rounded,
                  title: 'Lịch học',
                  value: data.schedule == null
                      ? 'Chưa có lịch học'
                      : '${data.schedule!.weekdayLabel}, ${data.schedule!.timeRange}',
                ),
                const SizedBox(height: 12),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  title: 'Phòng học',
                  value: subject.room.isEmpty ? 'Chưa cập nhật' : subject.room,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StudyFlowSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const <Widget>[
                            StudyFlowIconBadge(
                              icon: Icons.assignment_outlined,
                              backgroundColor: Color(0xFFE9F1FF),
                              foregroundColor: Colors.blue,
                              size: 40,
                              iconSize: 18,
                              borderRadius: 14,
                            ),
                            SizedBox(height: 12),
                            Text('Deadline'),
                            SizedBox(height: 4),
                            Text('Thêm mới'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StudyFlowSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const <Widget>[
                            StudyFlowIconBadge(
                              icon: Icons.edit_calendar_rounded,
                              backgroundColor: Color(0xFFF1E9FF),
                              foregroundColor: Colors.purple,
                              size: 40,
                              iconSize: 18,
                              borderRadius: 14,
                            ),
                            SizedBox(height: 12),
                            Text('Kế hoạch'),
                            SizedBox(height: 4),
                            Text('Tạo mới'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Mô tả', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(
                  subject.note.isEmpty
                      ? 'Môn học cung cấp kiến thức nền tảng và sẽ được bổ sung mô tả khi bạn cập nhật thêm chi tiết.'
                      : subject.note,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        },
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
    return StudyFlowSurfaceCard(
      child: Row(
        children: <Widget>[
          StudyFlowIconBadge(
            icon: icon,
            backgroundColor: const Color(0xFFF2F5FB),
            foregroundColor: const Color(0xFF60728E),
            size: 40,
            iconSize: 18,
            borderRadius: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectDetailData {
  const _SubjectDetailData({
    required this.subject,
    required this.schedule,
    required this.progress,
  });

  final SubjectModel subject;
  final ScheduleModel? schedule;
  final int progress;
}
