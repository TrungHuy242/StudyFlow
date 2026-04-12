import 'package:intl/intl.dart';

import '../../deadlines/data/deadline_model.dart';
import '../../deadlines/data/deadline_repository.dart';
import '../../pomodoro/data/pomodoro_repository.dart';
import '../../pomodoro/data/pomodoro_session_model.dart';
import '../../study_plan/data/study_plan_model.dart';
import '../../study_plan/data/study_plan_repository.dart';

class AnalyticsAggregationService {
  AnalyticsAggregationService({
    required PomodoroRepository pomodoroRepository,
    required DeadlineRepository deadlineRepository,
    required StudyPlanRepository studyPlanRepository,
  })  : _pomodoroRepository = pomodoroRepository,
        _deadlineRepository = deadlineRepository,
        _studyPlanRepository = studyPlanRepository;

  final PomodoroRepository _pomodoroRepository;
  final DeadlineRepository _deadlineRepository;
  final StudyPlanRepository _studyPlanRepository;

  Future<AnalyticsSummary> loadSummary() async {
    final List<PomodoroSessionModel> sessions = await _pomodoroRepository.getSessions();
    final List<DeadlineModel> deadlines = await _deadlineRepository.getDeadlines();
    final List<StudyPlanModel> plans = await _studyPlanRepository.getPlans();

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime weekStart = today.subtract(Duration(days: now.weekday - 1));
    final List<DailyFocusData> focusByDay = <DailyFocusData>[];

    for (int index = 0; index < 7; index++) {
      final DateTime day = weekStart.add(Duration(days: index));
      final int totalMinutes = sessions
          .where((PomodoroSessionModel session) {
            final DateTime sessionDay = DateTime(
              session.sessionDate.year,
              session.sessionDate.month,
              session.sessionDate.day,
            );
            return session.type == 'Focus' && sessionDay == day;
          })
          .fold<int>(0, (int total, PomodoroSessionModel session) => total + session.duration);
      focusByDay.add(
        DailyFocusData(
          label: DateFormat('E').format(day),
          minutes: totalMinutes,
        ),
      );
    }

    final int focusMinutesThisWeek =
        focusByDay.fold<int>(0, (int total, DailyFocusData day) => total + day.minutes);
    final int completedDeadlines =
        deadlines.where((DeadlineModel deadline) => deadline.isDone).length;
    final int overdueDeadlines =
        deadlines.where((DeadlineModel deadline) => deadline.isOverdue).length;
    final int plannedSessions = plans.where((StudyPlanModel plan) {
      final DateTime date = DateTime(plan.planDate.year, plan.planDate.month, plan.planDate.day);
      return !date.isBefore(weekStart) && !date.isAfter(weekStart.add(const Duration(days: 6)));
    }).length;

    return AnalyticsSummary(
      focusMinutesThisWeek: focusMinutesThisWeek,
      completedDeadlines: completedDeadlines,
      overdueDeadlines: overdueDeadlines,
      plannedSessions: plannedSessions,
      focusByDay: focusByDay,
      deadlineBreakdown: <String, double>{
        'Done': completedDeadlines.toDouble(),
        'Overdue': overdueDeadlines.toDouble(),
        'Open': deadlines
            .where((DeadlineModel deadline) => !deadline.isDone && !deadline.isOverdue)
            .length
            .toDouble(),
      },
    );
  }
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.focusMinutesThisWeek,
    required this.completedDeadlines,
    required this.overdueDeadlines,
    required this.plannedSessions,
    required this.focusByDay,
    required this.deadlineBreakdown,
  });

  final int focusMinutesThisWeek;
  final int completedDeadlines;
  final int overdueDeadlines;
  final int plannedSessions;
  final List<DailyFocusData> focusByDay;
  final Map<String, double> deadlineBreakdown;
}

class DailyFocusData {
  const DailyFocusData({
    required this.label,
    required this.minutes,
  });

  final String label;
  final int minutes;
}
