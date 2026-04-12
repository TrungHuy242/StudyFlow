// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../auth/application/app_session_controller.dart';
import '../../deadlines/data/deadline_model.dart';
import '../../deadlines/data/deadline_repository.dart';
import '../../pomodoro/data/pomodoro_repository.dart';
import '../../pomodoro/data/pomodoro_session_model.dart';
import '../../schedule/data/schedule_model.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../semester/data/semester_model.dart';
import '../../semester/data/semester_repository.dart';
import '../../study_plan/data/study_plan_model.dart';
import '../../study_plan/data/study_plan_repository.dart';
import '../../subjects/data/subject_model.dart';
import '../../subjects/data/subject_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final SemesterRepository _semesterRepository;
  late final SubjectRepository _subjectRepository;
  late final ScheduleRepository _scheduleRepository;
  late final DeadlineRepository _deadlineRepository;
  late final StudyPlanRepository _studyPlanRepository;
  late final PomodoroRepository _pomodoroRepository;
  late final AppRefreshNotifier _refreshNotifier;
  late Future<_DashboardData> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final DatabaseService databaseService = context.read<DatabaseService>();
    _semesterRepository = SemesterRepository(databaseService);
    _subjectRepository = SubjectRepository(databaseService);
    _scheduleRepository = ScheduleRepository(databaseService);
    _deadlineRepository = DeadlineRepository(databaseService);
    _studyPlanRepository = StudyPlanRepository(databaseService);
    _pomodoroRepository = PomodoroRepository(databaseService);
    _refreshNotifier = context.read<AppRefreshNotifier>();
    _refreshNotifier.addListener(_refreshFromOutside);
    _future = _loadDashboard();
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _refreshNotifier.removeListener(_refreshFromOutside);
    }
    super.dispose();
  }

  void _refreshFromOutside() {
    if (mounted) {
      _refresh();
    }
  }

  Future<_DashboardData> _loadDashboard() async {
    final SemesterModel? activeSemester = await _semesterRepository.getActiveSemester();
    final List<SubjectModel> subjects = await _subjectRepository.getSubjects();
    final List<ScheduleModel> schedules = await _scheduleRepository.getSchedules();
    final List<DeadlineModel> deadlines = await _deadlineRepository.getDeadlines();
    final List<StudyPlanModel> plans = await _studyPlanRepository.getPlans();
    final List<PomodoroSessionModel> sessions = await _pomodoroRepository.getSessions();

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<ScheduleModel> todaySchedule =
        schedules.where((ScheduleModel item) => item.weekday == now.weekday).toList()
          ..sort((ScheduleModel a, ScheduleModel b) => a.startTime.compareTo(b.startTime));
    final List<DeadlineModel> upcomingDeadlines = deadlines
        .where((DeadlineModel item) => !item.isDone && !item.dueAt.isBefore(today))
        .toList()
      ..sort((DeadlineModel a, DeadlineModel b) => a.dueAt.compareTo(b.dueAt));
    final List<StudyPlanModel> todayPlans = plans.where((StudyPlanModel item) {
      final DateTime date = DateTime(item.planDate.year, item.planDate.month, item.planDate.day);
      return date == today;
    }).toList();
    final int focusMinutesToday = sessions
        .where((PomodoroSessionModel session) {
          final DateTime date = DateTime(
            session.sessionDate.year,
            session.sessionDate.month,
            session.sessionDate.day,
          );
          return session.type == 'Focus' && date == today;
        })
        .fold<int>(0, (int sum, PomodoroSessionModel item) => sum + item.duration);

    final Map<String, List<DeadlineModel>> grouped = <String, List<DeadlineModel>>{};
    for (final DeadlineModel item in deadlines) {
      final String key = item.subjectName?.isNotEmpty == true ? item.subjectName! : item.title;
      grouped.putIfAbsent(key, () => <DeadlineModel>[]).add(item);
    }

    final List<_SubjectProgress> progress = subjects.map((SubjectModel subject) {
      final List<DeadlineModel> items = grouped[subject.name] ?? <DeadlineModel>[];
      final int average = items.isEmpty
          ? 0
          : items.fold<int>(0, (int sum, DeadlineModel item) => sum + item.progress) ~/
              items.length;
      return _SubjectProgress(subject.name, subject.displayColor, average.clamp(0, 100));
    }).toList()
      ..sort((_SubjectProgress a, _SubjectProgress b) => b.value.compareTo(a.value));

    return _DashboardData(
      activeSemester: activeSemester,
      subjects: subjects,
      todaySchedule: todaySchedule,
      upcomingDeadlines: upcomingDeadlines.take(3).toList(),
      todayPlans: todayPlans,
      focusMinutesToday: focusMinutesToday,
      progress: progress.take(3).toList(),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadDashboard();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<_DashboardData> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final _DashboardData data = snapshot.data ?? const _DashboardData();
          if (data.showEmpty) {
            return _DashboardEmpty(onSetup: () => context.push('/semester'));
          }
          if (data.goalReached) {
            return _DashboardGoal(
              focusMinutesToday: data.focusMinutesToday,
              onAnalytics: () => context.push('/analytics'),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                _DashboardHero(data: data, displayName: context.read<AppSessionController>().settings?.displayName ?? ''),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: StudyFlowSurfaceCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const StudyFlowIconBadge(
                              icon: Icons.calendar_month_rounded,
                              backgroundColor: Color(0xFFE9F1FF),
                              foregroundColor: StudyFlowPalette.blue,
                              size: 44,
                              iconSize: 18,
                              borderRadius: 14,
                            ),
                            title: Text(data.activeSemester?.name ?? 'Thiết lập học kỳ'),
                            subtitle: Text(
                              data.activeSemester == null
                                  ? 'Chọn thời gian học kỳ của bạn'
                                  : 'Còn ${data.remainingWeeks} tuần',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () => context.push('/semester'),
                          ),
                        ),
                      ),
                      const _SectionTitle('Lịch học hôm nay', route: '/calendar'),
                      const SizedBox(height: 12),
                      ...data.todaySchedule.isEmpty
                          ? const <Widget>[
                              _MessageCard(
                                title: 'Chưa có lịch học hôm nay',
                                subtitle: 'Thêm lịch học để bắt đầu theo dõi.',
                              ),
                            ]
                          : data.todaySchedule
                              .map((ScheduleModel item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ScheduleCard(item),
                                  ))
                              .toList(),
                      const SizedBox(height: 18),
                      const _SectionTitle('Deadline sắp tới', route: '/deadlines'),
                      const SizedBox(height: 12),
                      ...data.upcomingDeadlines.isEmpty
                          ? const <Widget>[
                              _MessageCard(
                                title: 'Không có deadline gần',
                                subtitle: 'Mọi thứ đang đúng tiến độ.',
                              ),
                            ]
                          : data.upcomingDeadlines
                              .map((DeadlineModel item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _DeadlineCard(item),
                                  ))
                              .toList(),
                      const SizedBox(height: 18),
                      Text('Hành động nhanh', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.play_arrow_rounded,
                              color: StudyFlowPalette.blue,
                              title: 'Bắt đầu học',
                              subtitle: 'Focus Timer',
                              onTap: () => context.push('/pomodoro'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.edit_calendar_rounded,
                              color: StudyFlowPalette.purple,
                              title: 'Tạo kế hoạch',
                              subtitle: 'Lên lịch ôn tập',
                              onTap: () => context.push('/study-plan'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _SectionTitle('Tiến độ môn học', route: '/subjects'),
                      const SizedBox(height: 12),
                      ...data.progress.isEmpty
                          ? const <Widget>[
                              _MessageCard(
                                title: 'Chưa có dữ liệu tiến độ',
                                subtitle: 'Thêm môn học và deadline để hiển thị tiến độ.',
                              ),
                            ]
                          : data.progress
                              .map((_SubjectProgress item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _SubjectProgressRow(item),
                                  ))
                              .toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.data, required this.displayName});

  final _DashboardData data;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: StudyFlowPalette.splashGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 56, 22, 30),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Chào buổi sáng',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName.isNotEmpty ? displayName : 'Sinh viên',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                    ),
                  ],
                ),
              ),
              StudyFlowCircleIconButton(
                icon: Icons.notifications_none_rounded,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: 10),
              const StudyFlowCircleIconButton(
                icon: Icons.person_outline_rounded,
                backgroundColor: Color(0x33FFFFFF),
                foregroundColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(child: _HeroStat('${(data.focusMinutesToday / 60).toStringAsFixed(1)} h', 'Học hôm nay')),
              const SizedBox(width: 12),
              Expanded(child: _HeroStat('${data.upcomingDeadlines.length}', 'Deadline')),
              const SizedBox(width: 12),
              Expanded(child: _HeroStat('${data.todayPlans.length}', 'Hoàn thành')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.route});

  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        GestureDetector(
          onTap: () => context.push(route),
          child: Text(
            'Xem tất cả',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: StudyFlowPalette.blue),
          ),
        ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard(this.item);

  final ScheduleModel item;

  @override
  Widget build(BuildContext context) {
    return StudyFlowSurfaceCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.displayColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.menu_book_rounded, color: item.displayColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.subjectName ?? 'Môn học'),
                const SizedBox(height: 4),
                Text(item.type.isEmpty ? item.room : item.type, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    const Icon(Icons.schedule_rounded, size: 14, color: StudyFlowPalette.textMuted),
                    const SizedBox(width: 4),
                    Text(item.timeRange, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          Text(item.room, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: StudyFlowPalette.textPrimary)),
        ],
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard(this.item);

  final DeadlineModel item;

  @override
  Widget build(BuildContext context) {
    final int remainingDays = DateTimeUtils.daysUntil(item.dueDate);
    return StudyFlowSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(item.title)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: item.displayColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${remainingDays.abs()} ngày',
                  style: TextStyle(color: item.displayColor, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.subjectName ?? 'Môn học', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.schedule_rounded, size: 14, color: StudyFlowPalette.textMuted),
              const SizedBox(width: 4),
              Text(item.dueTime ?? '23:59', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 12),
              const Icon(Icons.event_rounded, size: 14, color: StudyFlowPalette.textMuted),
              const SizedBox(width: 4),
              Text(DateTimeUtils.toDbDate(item.dueDate), style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: StudyFlowProgressBar(value: item.progress / 100, color: item.displayColor, height: 8)),
              const SizedBox(width: 10),
              Text('${item.progress} %', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: StudyFlowSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StudyFlowIconBadge(
              icon: icon,
              backgroundColor: color.withValues(alpha: 0.14),
              foregroundColor: color,
              size: 40,
              iconSize: 18,
              borderRadius: 14,
            ),
            const SizedBox(height: 14),
            Text(title),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SubjectProgressRow extends StatelessWidget {
  const _SubjectProgressRow(this.item);

  final _SubjectProgress item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(item.name.isEmpty ? '?' : item.name[0].toUpperCase(), style: TextStyle(color: item.color, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text(item.name)),
                  Text('${item.value} %', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              StudyFlowProgressBar(value: item.value / 100, color: item.color, height: 4),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return StudyFlowSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 56, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: const <Widget>[
                  Expanded(child: Text('Dashboard', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700))),
                  StudyFlowCircleIconButton(icon: Icons.notifications_none_rounded),
                  SizedBox(width: 10),
                  StudyFlowCircleIconButton(icon: Icons.person_outline_rounded),
                ],
              ),
              const Spacer(),
              const Center(
                child: StudyFlowIconBadge(
                  icon: Icons.menu_book_rounded,
                  backgroundColor: Color(0xFFEFF4FD),
                  foregroundColor: Color(0xFFA9BEDC),
                  size: 80,
                  iconSize: 36,
                  borderRadius: 26,
                ),
              ),
              const SizedBox(height: 20),
              Center(child: Text('Chưa có dữ liệu', style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Bắt đầu bằng cách thêm môn học và\nthiết lập học kỳ của bạn',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              StudyFlowGradientButton(label: 'Thiết lập học kỳ', onTap: onSetup),
              const SizedBox(height: 14),
              StudyFlowOutlineButton(label: 'Thêm môn học', onTap: () => context.push('/subjects/add')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardGoal extends StatelessWidget {
  const _DashboardGoal({
    required this.focusMinutesToday,
    required this.onAnalytics,
  });

  final int focusMinutesToday;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyFlowPalette.backgroundWarm,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 48, 22, 24),
          children: <Widget>[
            const Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: StudyFlowPalette.green,
                child: Icon(Icons.check_rounded, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Center(child: Text('Chúc mừng!', style: Theme.of(context).textTheme.headlineSmall)),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Bạn đã hoàn thành mục tiêu học tập hôm nay',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            StudyFlowSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Siêu sao học tập', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Hoàn thành 10 deadline trong tuần này', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(child: _GoalStatCard(color: StudyFlowPalette.green, value: '7', label: 'Ngày liên tiếp')),
                const SizedBox(width: 12),
                const Expanded(child: _GoalStatCard(color: StudyFlowPalette.blue, value: '100%', label: 'Mục tiêu đạt')),
              ],
            ),
            const SizedBox(height: 18),
            Text('Tóm tắt hôm nay', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _MessageCard(title: 'Phiên học Pomodoro', subtitle: '${focusMinutesToday ~/ 25} phiên'),
            const SizedBox(height: 10),
            _MessageCard(title: 'Thời gian học', subtitle: '${(focusMinutesToday / 60).toStringAsFixed(1)} giờ'),
            const SizedBox(height: 20),
            StudyFlowGradientButton(label: 'Xem thống kê chi tiết', onTap: onAnalytics),
          ],
        ),
      ),
    );
  }
}

class _GoalStatCard extends StatelessWidget {
  const _GoalStatCard({
    required this.color,
    required this.value,
    required this.label,
  });

  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return StudyFlowSurfaceCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    this.activeSemester,
    this.subjects = const <SubjectModel>[],
    this.todaySchedule = const <ScheduleModel>[],
    this.upcomingDeadlines = const <DeadlineModel>[],
    this.todayPlans = const <StudyPlanModel>[],
    this.focusMinutesToday = 0,
    this.progress = const <_SubjectProgress>[],
  });

  final SemesterModel? activeSemester;
  final List<SubjectModel> subjects;
  final List<ScheduleModel> todaySchedule;
  final List<DeadlineModel> upcomingDeadlines;
  final List<StudyPlanModel> todayPlans;
  final int focusMinutesToday;
  final List<_SubjectProgress> progress;

  bool get showEmpty => activeSemester == null || subjects.isEmpty;
  bool get goalReached => focusMinutesToday >= 120;
  int get remainingWeeks {
    if (activeSemester == null) return 0;
    return activeSemester!.endDate.difference(DateTime.now()).inDays ~/ 7;
  }
}

class _SubjectProgress {
  const _SubjectProgress(this.name, this.color, this.value);

  final String name;
  final Color color;
  final int value;
}

