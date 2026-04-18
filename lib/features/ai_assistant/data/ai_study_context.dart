import '../../deadlines/data/deadline_model.dart';
import '../../notes/data/note_model.dart';
import '../../pomodoro/data/pomodoro_session_model.dart';
import '../../schedule/data/schedule_model.dart';
import '../../study_plan/data/study_plan_model.dart';

class AiStudyContext {
  const AiStudyContext({
    required this.displayName,
    required this.studyGoalMinutes,
    required this.focusDurationMinutes,
    required this.shortBreakMinutes,
    required this.generatedAt,
    required this.deadlines,
    required this.schedules,
    required this.plans,
    required this.sessions,
    required this.notes,
  });

  final String displayName;
  final int studyGoalMinutes;
  final int focusDurationMinutes;
  final int shortBreakMinutes;
  final DateTime generatedAt;
  final List<DeadlineModel> deadlines;
  final List<ScheduleModel> schedules;
  final List<StudyPlanModel> plans;
  final List<PomodoroSessionModel> sessions;
  final List<NoteModel> notes;

  bool get hasAnyData =>
      deadlines.isNotEmpty ||
      schedules.isNotEmpty ||
      plans.isNotEmpty ||
      sessions.isNotEmpty ||
      notes.isNotEmpty;

  List<DeadlineModel> get overdueDeadlines => deadlines
      .where((DeadlineModel item) => item.isOverdue)
      .toList(growable: false);

  List<DeadlineModel> get openDeadlines => deadlines
      .where((DeadlineModel item) => !item.isDone)
      .toList(growable: false);

  List<DeadlineModel> get upcomingDeadlines => deadlines
      .where(
        (DeadlineModel item) =>
            !item.isDone && !item.isOverdue && !_isBeforeToday(item.dueDate),
      )
      .toList(growable: false);

  List<ScheduleModel> schedulesForDate(DateTime date) {
    return schedules
        .where((ScheduleModel item) => item.weekday == date.weekday)
        .toList(growable: false);
  }

  List<StudyPlanModel> plansForDate(DateTime date) {
    return plans
        .where((StudyPlanModel item) => _isSameDate(item.planDate, date))
        .toList(growable: false);
  }

  List<StudyPlanModel> plansForCurrentWeek() {
    final DateTime start = _startOfWeek(generatedAt);
    final DateTime end = start.add(const Duration(days: 7));
    return plans.where((StudyPlanModel item) {
      final DateTime day = _dateOnly(item.planDate);
      return !day.isBefore(start) && day.isBefore(end);
    }).toList(growable: false);
  }

  int focusMinutesForDate(DateTime date) {
    return sessions.where((PomodoroSessionModel item) {
      return item.type == 'Focus' && _isSameDate(item.sessionDate, date);
    }).fold<int>(
        0, (int sum, PomodoroSessionModel item) => sum + item.duration);
  }

  int focusMinutesThisWeek() {
    final DateTime start = _startOfWeek(generatedAt);
    final DateTime end = start.add(const Duration(days: 7));
    return sessions.where((PomodoroSessionModel item) {
      if (item.type != 'Focus') {
        return false;
      }
      final DateTime day = _dateOnly(item.sessionDate);
      return !day.isBefore(start) && day.isBefore(end);
    }).fold<int>(
        0, (int sum, PomodoroSessionModel item) => sum + item.duration);
  }

  static DateTime dateOnly(DateTime value) => _dateOnly(value);

  static DateTime startOfWeek(DateTime value) => _startOfWeek(value);

  static bool isSameDate(DateTime left, DateTime right) =>
      _isSameDate(left, right);

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isBeforeToday(DateTime value) {
    return _dateOnly(value).isBefore(_dateOnly(DateTime.now()));
  }

  static bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static DateTime _startOfWeek(DateTime value) {
    final DateTime day = _dateOnly(value);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}
