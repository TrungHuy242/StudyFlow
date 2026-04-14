import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../deadlines/data/deadline_repository.dart';
import '../../pomodoro/data/pomodoro_repository.dart';
import '../../study_plan/data/study_plan_repository.dart';
import '../../subjects/data/subject_repository.dart';
import '../data/analytics_aggregation_service.dart';

enum _AnalyticsScreen {
  overview,
  subjectProgress,
  deadlineStats,
  weeklyChart,
  streak,
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsAggregationService? _service;
  AppRefreshNotifier? _refreshNotifier;
  Future<AnalyticsSummary>? _future;
  _AnalyticsScreen _screen = _AnalyticsScreen.overview;

  void _ensureInitialized() {
    _service ??= AnalyticsAggregationService(
      pomodoroRepository: PomodoroRepository(context.read<DatabaseService>()),
      deadlineRepository: DeadlineRepository(context.read<DatabaseService>()),
      studyPlanRepository: StudyPlanRepository(context.read<DatabaseService>()),
      subjectRepository: SubjectRepository(context.read<DatabaseService>()),
    );

    final AppRefreshNotifier refreshNotifier =
        context.read<AppRefreshNotifier>();
    if (!identical(_refreshNotifier, refreshNotifier)) {
      _refreshNotifier?.removeListener(_handleExternalRefresh);
      _refreshNotifier = refreshNotifier;
      _refreshNotifier!.addListener(_handleExternalRefresh);
    }

    _future ??= _service!.loadSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureInitialized();
  }

  @override
  void dispose() {
    _refreshNotifier?.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  void _handleExternalRefresh() {
    if (!mounted) {
      return;
    }
    _refresh();
  }

  Future<void> _refresh() async {
    _ensureInitialized();
    final AnalyticsAggregationService? service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _future = service.loadSummary();
    });
    await _future;
  }

  void _openScreen(_AnalyticsScreen value) {
    setState(() {
      _screen = value;
    });
  }

  void _backToOverview() {
    if (_screen == _AnalyticsScreen.overview) {
      return;
    }
    setState(() {
      _screen = _AnalyticsScreen.overview;
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<AnalyticsSummary>(
        future: _future ?? _service?.loadSummary(),
        builder: (
          BuildContext context,
          AsyncSnapshot<AnalyticsSummary> snapshot,
        ) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState(message: 'Đang tải thống kê...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Không thể tải thống kê',
              message: 'Hãy thử làm mới sau khi dữ liệu học tập được lưu xong.',
              onAction: _refresh,
            );
          }

          final AnalyticsSummary summary = snapshot.data ??
              AnalyticsSummary(
                focusMinutesThisWeek: 0,
                totalFocusMinutes: 0,
                completedDeadlines: 0,
                overdueDeadlines: 0,
                openDeadlines: 0,
                plannedSessionsThisWeek: 0,
                focusByDay: <DailyFocusData>[],
                deadlineBreakdown: <String, double>{},
                subjectProgress: <SubjectProgressData>[],
                currentStreakDays: 0,
                bestStreakDays: 0,
                daysToNextRecord: 1,
                activeWeekdays: <int>{},
                activeStudyDays: <DateTime>{},
                achievements: <AchievementData>[],
                deadlineCompletionRate: 0,
              );

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey<_AnalyticsScreen>(_screen),
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: _buildScreen(summary),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreen(AnalyticsSummary summary) {
    switch (_screen) {
      case _AnalyticsScreen.subjectProgress:
        return _SubjectProgressView(
          summary: summary,
          onBack: _backToOverview,
        );
      case _AnalyticsScreen.deadlineStats:
        return _DeadlineStatsView(
          summary: summary,
          onBack: _backToOverview,
        );
      case _AnalyticsScreen.weeklyChart:
        return _WeeklyChartView(
          summary: summary,
          onBack: _backToOverview,
        );
      case _AnalyticsScreen.streak:
        return _StreakView(
          summary: summary,
          onBack: _backToOverview,
        );
      case _AnalyticsScreen.overview:
        return _AnalyticsOverviewView(
          summary: summary,
          onOpenScreen: _openScreen,
        );
    }
  }
}

class _AnalyticsOverviewView extends StatelessWidget {
  const _AnalyticsOverviewView({
    required this.summary,
    required this.onOpenScreen,
  });

  final AnalyticsSummary summary;
  final ValueChanged<_AnalyticsScreen> onOpenScreen;

  @override
  Widget build(BuildContext context) {
    final AchievementData achievement = summary.achievements.isEmpty
        ? AchievementData(
            title: 'Sẵn sàng bắt đầu',
            description: 'Hoàn thành một phiên focus để mở khóa thống kê.',
            accentHex: '#64748B',
          )
        : summary.achievements.first;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: <Widget>[
        _OverviewHero(summary: summary),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AnalyticsSectionCard(
                title: 'Hoạt động tuần này',
                actionLabel: 'Chi tiết',
                onTapAction: () => onOpenScreen(_AnalyticsScreen.weeklyChart),
                child: _MiniFocusChart(
                  data: summary.focusByDay,
                  height: 120,
                ),
              ),
              const SizedBox(height: 18),
              _AnalyticsSectionCard(
                title: 'Deadline',
                actionLabel: 'Chi tiết',
                onTapAction: () => onOpenScreen(_AnalyticsScreen.deadlineStats),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _MiniNumberStat(
                            label: 'Hoàn thành',
                            value: '${summary.completedDeadlines}',
                            valueColor: StudyFlowPalette.green,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MiniNumberStat(
                            label: 'Còn lại',
                            value:
                                '${summary.openDeadlines + summary.overdueDeadlines}',
                            valueColor: StudyFlowPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SegmentedProgressBar(
                      segments: <_ProgressSegment>[
                        _ProgressSegment(
                          value: summary.completedDeadlines.toDouble(),
                          color: StudyFlowPalette.green,
                        ),
                        _ProgressSegment(
                          value: summary.overdueDeadlines.toDouble(),
                          color: StudyFlowPalette.orange,
                        ),
                        _ProgressSegment(
                          value: summary.openDeadlines.toDouble(),
                          color: StudyFlowPalette.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _AnalyticsSectionCard(
                title: 'Tiến độ theo môn',
                actionLabel: 'Chi tiết',
                onTapAction: () =>
                    onOpenScreen(_AnalyticsScreen.subjectProgress),
                child: Column(
                  children: summary.subjectProgress
                      .take(5)
                      .map((SubjectProgressData item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _SubjectOverviewRow(item: item),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              _AnalyticsSectionCard(
                title: 'Thành tựu gần đây',
                child: _AchievementTile(achievement: achievement),
              ),
              const SizedBox(height: 18),
              _AnalyticsSectionCard(
                title: 'Chuỗi ngày học',
                actionLabel: 'Chi tiết',
                onTapAction: () => onOpenScreen(_AnalyticsScreen.streak),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _MiniNumberStat(
                        label: 'Hiện tại',
                        value: '${summary.currentStreakDays}',
                        valueColor: StudyFlowPalette.blue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MiniNumberStat(
                        label: 'Kỷ lục',
                        value: '${summary.bestStreakDays}',
                        valueColor: StudyFlowPalette.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0F172A),
            Color(0xFF172554),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 4),
              const Text(
                'Thống kê',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _HeroInfoCard(
                      label: 'Chuỗi ngày',
                      value: '${summary.currentStreakDays}',
                      subtitle: 'ngày liên tiếp',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _HeroInfoCard(
                      label: 'Giờ học',
                      value: _formatHourValue(summary.totalFocusMinutes),
                      subtitle: 'tổng thời gian',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroInfoCard extends StatelessWidget {
  const _HeroInfoCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectProgressView extends StatelessWidget {
  const _SubjectProgressView({
    required this.summary,
    required this.onBack,
  });

  final AnalyticsSummary summary;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: <Widget>[
          _DetailHeader(
            title: 'Tiến độ theo môn',
            onBack: onBack,
          ),
          const SizedBox(height: 20),
          ...summary.subjectProgress.map((SubjectProgressData item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _SubjectProgressCard(item: item),
            );
          }),
        ],
      ),
    );
  }
}

class _DeadlineStatsView extends StatelessWidget {
  const _DeadlineStatsView({
    required this.summary,
    required this.onBack,
  });

  final AnalyticsSummary summary;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: <Widget>[
          _DetailHeader(
            title: 'Thống kê Deadline',
            onBack: onBack,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF4338CA),
                  Color(0xFF6366F1),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  _formatPercent(summary.deadlineCompletionRate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tỷ lệ hoàn thành',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatBox(
                  value: '${summary.completedDeadlines}',
                  label: 'Đã hoàn thành',
                  valueColor: StudyFlowPalette.textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatBox(
                  value: '${summary.openDeadlines + summary.overdueDeadlines}',
                  label: 'Còn lại',
                  valueColor: StudyFlowPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AnalyticsSectionCard(
            title: 'Tổng quan',
            child: Column(
              children: <Widget>[
                _LegendRow(
                  color: StudyFlowPalette.green,
                  label: 'Hoàn thành',
                  value: '${summary.completedDeadlines}',
                ),
                const SizedBox(height: 12),
                _LegendRow(
                  color: StudyFlowPalette.orange,
                  label: 'Quá hạn',
                  value: '${summary.overdueDeadlines}',
                ),
                const SizedBox(height: 12),
                _LegendRow(
                  color: StudyFlowPalette.textMuted,
                  label: 'Đang mở',
                  value: '${summary.openDeadlines}',
                ),
                const SizedBox(height: 18),
                _SegmentedProgressBar(
                  segments: <_ProgressSegment>[
                    _ProgressSegment(
                      value: summary.completedDeadlines.toDouble(),
                      color: StudyFlowPalette.green,
                    ),
                    _ProgressSegment(
                      value: summary.overdueDeadlines.toDouble(),
                      color: StudyFlowPalette.orange,
                    ),
                    _ProgressSegment(
                      value: summary.openDeadlines.toDouble(),
                      color: StudyFlowPalette.textMuted,
                    ),
                  ],
                  height: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChartView extends StatelessWidget {
  const _WeeklyChartView({
    required this.summary,
    required this.onBack,
  });

  final AnalyticsSummary summary;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: <Widget>[
          _DetailHeader(
            title: 'Biểu đồ tuần',
            onBack: onBack,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF0F172A),
                  Color(0xFF1E3A8A),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tổng giờ học tuần này',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatHourValue(summary.focusMinutesThisWeek),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _AnalyticsSectionCard(
            title: 'Giờ học theo ngày',
            child: _MiniFocusChart(
              data: summary.focusByDay,
              height: 220,
              showValueLabels: true,
              highlightMax: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakView extends StatelessWidget {
  const _StreakView({
    required this.summary,
    required this.onBack,
  });

  final AnalyticsSummary summary;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF0F172A),
                Color(0xFF1E293B),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
              child: Column(
                children: <Widget>[
                  _DetailHeader(
                    title: 'Chuỗi ngày học',
                    onBack: onBack,
                    onDarkBackground: true,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '${summary.currentStreakDays}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ngày liên tiếp',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Tuần này',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              _WeeklyStreakRow(activeWeekdays: summary.activeWeekdays),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _StatBox(
                      value: '${summary.bestStreakDays}',
                      label: 'Kỷ lục',
                      valueColor: StudyFlowPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatBox(
                      value: '${summary.daysToNextRecord}',
                      label: 'Ngày nữa để kỷ lục',
                      valueColor: StudyFlowPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Tiếp tục duy trì chuỗi ngày học để đạt được kỷ lục mới!',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.title,
    required this.onBack,
    this.onDarkBackground = false,
  });

  final String title;
  final VoidCallback onBack;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final Color iconBackground = onDarkBackground
        ? Colors.white.withValues(alpha: 0.12)
        : StudyFlowPalette.surfaceSoft;
    final Color iconColor =
        onDarkBackground ? Colors.white : StudyFlowPalette.textPrimary;
    final Color titleColor =
        onDarkBackground ? Colors.white : const Color(0xFF0F172A);

    return Row(
      children: <Widget>[
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: iconColor,
              size: 18,
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 42),
      ],
    );
  }
}

class _AnalyticsSectionCard extends StatelessWidget {
  const _AnalyticsSectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onTapAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onTapAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: StudyFlowPalette.border),
        boxShadow: StudyFlowPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actionLabel != null && onTapAction != null)
                InkWell(
                  onTap: onTapAction,
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: StudyFlowPalette.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MiniNumberStat extends StatelessWidget {
  const _MiniNumberStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: StudyFlowPalette.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StudyFlowPalette.border),
        boxShadow: StudyFlowPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: StudyFlowPalette.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectOverviewRow extends StatelessWidget {
  const _SubjectOverviewRow({required this.item});

  final SubjectProgressData item;

  @override
  Widget build(BuildContext context) {
    final Color color = _hexColor(item.colorHex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Text(
              '${item.progress} %',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StudyFlowProgressBar(
          value: item.progress / 100,
          color: color,
          height: 8,
        ),
      ],
    );
  }
}

class _SubjectProgressCard extends StatelessWidget {
  const _SubjectProgressCard({required this.item});

  final SubjectProgressData item;

  @override
  Widget build(BuildContext context) {
    final Color color = _hexColor(item.colorHex);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: StudyFlowPalette.border),
        boxShadow: StudyFlowPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${item.progress} %',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StudyFlowProgressBar(
            value: item.progress / 100,
            color: color,
            height: 12,
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Focus ${_formatHourValue(item.focusMinutes)}',
                  style: const TextStyle(
                    color: StudyFlowPalette.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Text(
                '${item.completedDeadlines}/${item.totalDeadlines} deadline',
                style: const TextStyle(
                  color: StudyFlowPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final AchievementData achievement;

  @override
  Widget build(BuildContext context) {
    final Color accent = _hexColor(achievement.accentHex);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.workspace_premium_rounded,
            color: accent,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                achievement.title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                achievement.description,
                style: const TextStyle(
                  color: StudyFlowPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniFocusChart extends StatelessWidget {
  const _MiniFocusChart({
    required this.data,
    required this.height,
    this.showValueLabels = false,
    this.highlightMax = false,
  });

  final List<DailyFocusData> data;
  final double height;
  final bool showValueLabels;
  final bool highlightMax;

  @override
  Widget build(BuildContext context) {
    final int maxMinutes = data.isEmpty
        ? 0
        : data.map((DailyFocusData item) => item.minutes).reduce(math.max);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double availableHeight = constraints.maxHeight;
          final double valueLabelHeight = showValueLabels ? 22 : 0;
          final double valueGap = showValueLabels ? 8 : 0;
          const double barGap = 10;
          const double dayLabelHeight = 16;
          final double maxBarHeight = math.max(
            12,
            availableHeight -
                valueLabelHeight -
                valueGap -
                barGap -
                dayLabelHeight,
          );
          final double minBarHeight = showValueLabels ? 12 : 16;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((DailyFocusData item) {
              final bool isPeak =
                  highlightMax && item.minutes == maxMinutes && maxMinutes > 0;
              final Color color =
                  isPeak ? StudyFlowPalette.blue : const Color(0xFFD8E4FF);
              final double ratio =
                  maxMinutes == 0 ? 0 : item.minutes / maxMinutes;
              final double barHeight = item.minutes == 0
                  ? minBarHeight
                  : minBarHeight + (ratio * (maxBarHeight - minBarHeight));

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      if (showValueLabels) ...<Widget>[
                        SizedBox(
                          height: valueLabelHeight,
                          child: Center(
                            child: Text(
                              _formatDayValue(item.minutes),
                              style: TextStyle(
                                color: isPeak
                                    ? StudyFlowPalette.blue
                                    : const Color(0xFF475569),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: valueGap),
                      ],
                      Container(
                        width: 24,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: barGap),
                      SizedBox(
                        height: dayLabelHeight,
                        child: Center(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              color: StudyFlowPalette.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _WeeklyStreakRow extends StatelessWidget {
  const _WeeklyStreakRow({required this.activeWeekdays});

  final Set<int> activeWeekdays;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>[
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'CN'
    ];

    return Row(
      children: List<Widget>.generate(labels.length, (int index) {
        final int weekday = index + 1;
        final bool active = activeWeekdays.contains(weekday);
        return Expanded(
          child: Column(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active
                      ? StudyFlowPalette.blue
                      : StudyFlowPalette.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    active ? Icons.check_rounded : Icons.remove_rounded,
                    color: active ? Colors.white : StudyFlowPalette.textMuted,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                labels[index],
                style: const TextStyle(
                  color: StudyFlowPalette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: StudyFlowPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: StudyFlowPalette.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({
    required this.segments,
    this.height = 10,
  });

  final List<_ProgressSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double total = segments.fold<double>(
      0,
      (double sum, _ProgressSegment segment) => sum + segment.value,
    );

    if (total == 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: StudyFlowPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Row(
          children: segments.map((_ProgressSegment segment) {
            if (segment.value <= 0) {
              return const SizedBox.shrink();
            }
            return Expanded(
              flex: math.max(1, (segment.value / total * 1000).round()),
              child: Container(color: segment.color),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ProgressSegment {
  const _ProgressSegment({
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;
}

String _formatPercent(double value) {
  return '${(value * 100).round()} %';
}

String _formatHourValue(int minutes) {
  if (minutes <= 0) {
    return '0 h';
  }
  final double hours = minutes / 60;
  final bool isWhole = hours == hours.roundToDouble();
  return isWhole ? '${hours.toInt()} h' : '${hours.toStringAsFixed(1)} h';
}

String _formatDayValue(int minutes) {
  if (minutes == 0) {
    return '0 h';
  }
  final double hours = minutes / 60;
  final bool isWhole = hours == hours.roundToDouble();
  return isWhole ? '${hours.toInt()} h' : '${hours.toStringAsFixed(1)} h';
}

Color _hexColor(String hex) {
  return Color(int.parse(hex.replaceFirst('#', '0xFF')));
}
