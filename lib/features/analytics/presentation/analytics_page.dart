import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/app_stat_tile.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../deadlines/data/deadline_repository.dart';
import '../../pomodoro/data/pomodoro_repository.dart';
import '../../study_plan/data/study_plan_repository.dart';
import '../data/analytics_aggregation_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late final AnalyticsAggregationService _service;
  late final AppRefreshNotifier _refreshNotifier;
  late Future<AnalyticsSummary> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final DatabaseService databaseService = context.read<DatabaseService>();
    _service = AnalyticsAggregationService(
      pomodoroRepository: PomodoroRepository(databaseService),
      deadlineRepository: DeadlineRepository(databaseService),
      studyPlanRepository: StudyPlanRepository(databaseService),
    );
    _refreshNotifier = context.read<AppRefreshNotifier>();
    _refreshNotifier.addListener(_handleExternalRefresh);
    _future = _service.loadSummary();
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _refreshNotifier.removeListener(_handleExternalRefresh);
    }
    super.dispose();
  }

  void _handleExternalRefresh() {
    if (!mounted) {
      return;
    }
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.loadSummary();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<AnalyticsSummary>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<AnalyticsSummary> snapshot,
        ) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState(message: 'Loading analytics...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load analytics',
              message: 'Try again after your latest changes are saved.',
              onAction: _refresh,
            );
          }

          final AnalyticsSummary? summary = snapshot.data;
          if (summary == null) {
            return SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Analytics',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: AppEmptyState(
                          title: 'No analytics data yet',
                          message:
                              'Use pomodoro, deadlines, and study plans to build your stats.',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: <Widget>[
                  Text(
                    'Analytics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  StudyFlowSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'This week',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            SizedBox(
                              width: double.infinity,
                              child: AppStatTile(
                                label: 'Focus minutes',
                                value: '${summary.focusMinutesThisWeek}',
                                icon: Icons.timer_outlined,
                                color: StudyFlowPalette.blue,
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: AppStatTile(
                                label: 'Completed deadlines',
                                value: '${summary.completedDeadlines}',
                                icon: Icons.task_alt_rounded,
                                color: StudyFlowPalette.green,
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: AppStatTile(
                                label: 'Planned sessions',
                                value: '${summary.plannedSessions}',
                                icon: Icons.event_note_rounded,
                                color: StudyFlowPalette.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  StudyFlowSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Focus minutes by day',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                      final int index = value.toInt();
                                      if (index < 0 ||
                                          index >= summary.focusByDay.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        summary.focusByDay[index].label,
                                        style: const TextStyle(
                                          color: StudyFlowPalette.textSecondary,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: List<BarChartGroupData>.generate(
                                summary.focusByDay.length,
                                (int index) {
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: <BarChartRodData>[
                                      BarChartRodData(
                                        toY: summary.focusByDay[index]
                                            .minutes
                                            .toDouble(),
                                        width: 18,
                                        borderRadius: BorderRadius.circular(8),
                                        color: StudyFlowPalette.blue,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  StudyFlowSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Deadline breakdown',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 40,
                              sections: <PieChartSectionData>[
                                PieChartSectionData(
                                  value: summary.deadlineBreakdown['Done'] ?? 0,
                                  color: StudyFlowPalette.green,
                                  title: 'Done',
                                  radius: 52,
                                ),
                                PieChartSectionData(
                                  value:
                                      summary.deadlineBreakdown['Overdue'] ?? 0,
                                  color: StudyFlowPalette.red,
                                  title: 'Overdue',
                                  radius: 52,
                                ),
                                PieChartSectionData(
                                  value: summary.deadlineBreakdown['Open'] ?? 0,
                                  color: StudyFlowPalette.orange,
                                  title: 'Open',
                                  radius: 52,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
