import 'dart:math' as math;

import '../../deadlines/data/deadline_model.dart';
import '../../deadlines/data/deadline_repository.dart';
import '../../pomodoro/data/pomodoro_repository.dart';
import '../../pomodoro/data/pomodoro_session_model.dart';
import '../../study_plan/data/study_plan_model.dart';
import '../../study_plan/data/study_plan_repository.dart';
import '../../subjects/data/subject_model.dart';
import '../../subjects/data/subject_repository.dart';

class AnalyticsAggregationService {
  AnalyticsAggregationService({
    required PomodoroRepository pomodoroRepository,
    required DeadlineRepository deadlineRepository,
    required StudyPlanRepository studyPlanRepository,
    required SubjectRepository subjectRepository,
  })  : _pomodoroRepository = pomodoroRepository,
        _deadlineRepository = deadlineRepository,
        _studyPlanRepository = studyPlanRepository,
        _subjectRepository = subjectRepository;

  final PomodoroRepository _pomodoroRepository;
  final DeadlineRepository _deadlineRepository;
  final StudyPlanRepository _studyPlanRepository;
  final SubjectRepository _subjectRepository;

  Future<AnalyticsSummary> loadSummary() async {
    final List<PomodoroSessionModel> sessions =
        await _pomodoroRepository.getSessions();
    final List<DeadlineModel> deadlines =
        await _deadlineRepository.getDeadlines();
    final List<StudyPlanModel> plans = await _studyPlanRepository.getPlans();
    final List<SubjectModel> subjects = await _subjectRepository.getSubjects();

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime weekStart = today.subtract(Duration(days: now.weekday - 1));
    final DateTime weekEnd = weekStart.add(const Duration(days: 6));
    final List<PomodoroSessionModel> focusSessions = sessions
        .where((PomodoroSessionModel session) => session.type == 'Focus')
        .toList();

    final List<DailyFocusData> focusByDay =
        List<DailyFocusData>.generate(7, (int index) {
      final DateTime day = weekStart.add(Duration(days: index));
      final int totalMinutes =
          focusSessions.where((PomodoroSessionModel session) {
        final DateTime source = session.completedAt ?? session.sessionDate;
        final DateTime sessionDay =
            DateTime(source.year, source.month, source.day);
        return sessionDay == day;
      }).fold<int>(
        0,
        (int total, PomodoroSessionModel session) => total + session.duration,
      );
      return DailyFocusData(
        label: _weekdayLabel(day.weekday),
        weekday: day.weekday,
        minutes: totalMinutes,
      );
    });

    final int focusMinutesThisWeek = focusByDay.fold<int>(
      0,
      (int total, DailyFocusData day) => total + day.minutes,
    );
    final int totalFocusMinutes = focusSessions.fold<int>(
      0,
      (int total, PomodoroSessionModel session) => total + session.duration,
    );

    final int completedDeadlines =
        deadlines.where((DeadlineModel deadline) => deadline.isDone).length;
    final int overdueDeadlines =
        deadlines.where((DeadlineModel deadline) => deadline.isOverdue).length;
    final int openDeadlines = deadlines
        .where(
            (DeadlineModel deadline) => !deadline.isDone && !deadline.isOverdue)
        .length;

    final int plannedSessionsThisWeek = plans.where((StudyPlanModel plan) {
      final DateTime date =
          DateTime(plan.planDate.year, plan.planDate.month, plan.planDate.day);
      return !date.isBefore(weekStart) && !date.isAfter(weekEnd);
    }).length;

    final int currentStreakDays = _currentStreakDays(focusSessions, today);
    final int bestStreakDays = _bestStreakDays(focusSessions);
    final int daysToNextRecord = bestStreakDays == 0
        ? 1
        : math.max(0, (bestStreakDays + 1) - currentStreakDays);

    final Set<DateTime> activeStudyDays = focusSessions
        .map(
          (PomodoroSessionModel session) => _normalizeDate(
            session.completedAt ?? session.sessionDate,
          ),
        )
        .toSet();
    final Set<int> activeWeekdays = focusByDay
        .where((DailyFocusData day) => day.minutes > 0)
        .map((DailyFocusData day) => day.weekday)
        .toSet();

    final List<SubjectProgressData> subjectProgress =
        _buildSubjectProgress(subjects, deadlines, focusSessions);

    final List<AchievementData> achievements = _buildAchievements(
      focusMinutesThisWeek: focusMinutesThisWeek,
      completedDeadlines: completedDeadlines,
      currentStreakDays: currentStreakDays,
      totalFocusMinutes: totalFocusMinutes,
    );

    final double deadlineCompletionRate =
        deadlines.isEmpty ? 0 : completedDeadlines / deadlines.length;

    return AnalyticsSummary(
      focusMinutesThisWeek: focusMinutesThisWeek,
      totalFocusMinutes: totalFocusMinutes,
      completedDeadlines: completedDeadlines,
      overdueDeadlines: overdueDeadlines,
      openDeadlines: openDeadlines,
      plannedSessionsThisWeek: plannedSessionsThisWeek,
      focusByDay: focusByDay,
      deadlineBreakdown: <String, double>{
        'Done': completedDeadlines.toDouble(),
        'Overdue': overdueDeadlines.toDouble(),
        'Open': openDeadlines.toDouble(),
      },
      subjectProgress: subjectProgress,
      currentStreakDays: currentStreakDays,
      bestStreakDays: bestStreakDays,
      daysToNextRecord: daysToNextRecord,
      activeWeekdays: activeWeekdays,
      activeStudyDays: activeStudyDays,
      achievements: achievements,
      deadlineCompletionRate: deadlineCompletionRate,
    );
  }

  List<SubjectProgressData> _buildSubjectProgress(
    List<SubjectModel> subjects,
    List<DeadlineModel> deadlines,
    List<PomodoroSessionModel> focusSessions,
  ) {
    final Map<int, int> focusBySubjectId = <int, int>{};
    for (final PomodoroSessionModel session in focusSessions) {
      final int? subjectId = session.subjectId;
      if (subjectId == null) {
        continue;
      }
      focusBySubjectId[subjectId] =
          (focusBySubjectId[subjectId] ?? 0) + session.duration;
    }

    final int maxFocusMinutes = focusBySubjectId.values.isEmpty
        ? 0
        : focusBySubjectId.values.reduce(math.max);

    final List<SubjectProgressData> items =
        subjects.map((SubjectModel subject) {
      final List<DeadlineModel> subjectDeadlines = deadlines
          .where((DeadlineModel deadline) => deadline.subjectId == subject.id)
          .toList();
      final int doneCount = subjectDeadlines
          .where((DeadlineModel deadline) => deadline.isDone)
          .length;
      final int averageDeadlineProgress = subjectDeadlines.isEmpty
          ? 0
          : subjectDeadlines.map((DeadlineModel deadline) {
                if (deadline.isDone) {
                  return 100;
                }
                return deadline.progress.clamp(0, 100);
              }).reduce((int a, int b) => a + b) ~/
              subjectDeadlines.length;
      final int focusMinutes =
          subject.id == null ? 0 : (focusBySubjectId[subject.id!] ?? 0);
      final int focusScore = maxFocusMinutes == 0
          ? 0
          : ((focusMinutes / maxFocusMinutes) * 100).round().clamp(0, 100);

      final int progress;
      if (subjectDeadlines.isNotEmpty && focusMinutes > 0) {
        progress = ((averageDeadlineProgress * 0.7) + (focusScore * 0.3))
            .round()
            .clamp(0, 100);
      } else if (subjectDeadlines.isNotEmpty) {
        progress = averageDeadlineProgress.clamp(0, 100);
      } else if (focusMinutes > 0) {
        progress = focusScore;
      } else {
        progress = 0;
      }

      return SubjectProgressData(
        subjectId: subject.id,
        name: subject.name,
        colorHex: subject.color,
        progress: progress,
        focusMinutes: focusMinutes,
        completedDeadlines: doneCount,
        totalDeadlines: subjectDeadlines.length,
      );
    }).toList()
          ..sort((SubjectProgressData a, SubjectProgressData b) {
            final int byProgress = b.progress.compareTo(a.progress);
            if (byProgress != 0) {
              return byProgress;
            }
            return a.name.compareTo(b.name);
          });

    return items;
  }

  List<AchievementData> _buildAchievements({
    required int focusMinutesThisWeek,
    required int completedDeadlines,
    required int currentStreakDays,
    required int totalFocusMinutes,
  }) {
    final List<AchievementData> items = <AchievementData>[];

    if (completedDeadlines >= 10) {
      items.add(
        AchievementData(
          title: 'Sieu sao deadline',
          description: 'Hoan thanh 10 deadline tro len.',
          accentHex: '#F59E0B',
        ),
      );
    }
    if (currentStreakDays >= 7) {
      items.add(
        AchievementData(
          title: 'Chuoi hoc an tuong',
          description: 'Duy tri chuoi hoc tap 7 ngay lien tiep.',
          accentHex: '#2563EB',
        ),
      );
    }
    if (focusMinutesThisWeek >= 600) {
      items.add(
        AchievementData(
          title: 'Tap trung cao do',
          description: 'Dat 10 gio focus trong tuan nay.',
          accentHex: '#16A34A',
        ),
      );
    }
    if (items.isEmpty && totalFocusMinutes > 0) {
      items.add(
        AchievementData(
          title: 'Bat dau hanh trinh',
          description: 'Ban da co du lieu hoc tap dau tien.',
          accentHex: '#7C3AED',
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        AchievementData(
          title: 'San sang bat dau',
          description: 'Hoan thanh mot phien focus de mo khoa thong ke.',
          accentHex: '#64748B',
        ),
      );
    }

    return items;
  }

  int _currentStreakDays(
    List<PomodoroSessionModel> focusSessions,
    DateTime today,
  ) {
    if (focusSessions.isEmpty) {
      return 0;
    }

    final Set<DateTime> focusDays = focusSessions
        .map(
          (PomodoroSessionModel session) => _normalizeDate(
            session.completedAt ?? session.sessionDate,
          ),
        )
        .toSet();
    final List<DateTime> sortedDays = focusDays.toList()
      ..sort((DateTime a, DateTime b) => a.compareTo(b));
    final DateTime lastStudyDay = sortedDays.last;
    final int gapFromToday = today.difference(lastStudyDay).inDays;
    if (gapFromToday > 1) {
      return 0;
    }

    int streak = 0;
    DateTime cursor = gapFromToday == 0 ? today : lastStudyDay;
    while (focusDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _bestStreakDays(List<PomodoroSessionModel> focusSessions) {
    if (focusSessions.isEmpty) {
      return 0;
    }

    final List<DateTime> sortedDays = focusSessions
        .map(
          (PomodoroSessionModel session) => _normalizeDate(
            session.completedAt ?? session.sessionDate,
          ),
        )
        .toSet()
        .toList()
      ..sort((DateTime a, DateTime b) => a.compareTo(b));

    int best = 1;
    int current = 1;
    for (int index = 1; index < sortedDays.length; index++) {
      final int gap =
          sortedDays[index].difference(sortedDays[index - 1]).inDays;
      if (gap == 1) {
        current++;
      } else {
        current = 1;
      }
      best = math.max(best, current);
    }
    return best;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _weekdayLabel(int weekday) {
    const List<String> labels = <String>[
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'CN',
    ];
    return labels[weekday - 1];
  }
}

class AnalyticsSummary {
  AnalyticsSummary({
    required this.focusMinutesThisWeek,
    required this.totalFocusMinutes,
    required this.completedDeadlines,
    required this.overdueDeadlines,
    required this.openDeadlines,
    required this.plannedSessionsThisWeek,
    required this.focusByDay,
    required this.deadlineBreakdown,
    required this.subjectProgress,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.daysToNextRecord,
    required this.activeWeekdays,
    required this.activeStudyDays,
    required this.achievements,
    required this.deadlineCompletionRate,
  });

  final int focusMinutesThisWeek;
  final int totalFocusMinutes;
  final int completedDeadlines;
  final int overdueDeadlines;
  final int openDeadlines;
  final int plannedSessionsThisWeek;
  final List<DailyFocusData> focusByDay;
  final Map<String, double> deadlineBreakdown;
  final List<SubjectProgressData> subjectProgress;
  final int currentStreakDays;
  final int bestStreakDays;
  final int daysToNextRecord;
  final Set<int> activeWeekdays;
  final Set<DateTime> activeStudyDays;
  final List<AchievementData> achievements;
  final double deadlineCompletionRate;
}

class DailyFocusData {
  DailyFocusData({
    required this.label,
    required this.weekday,
    required this.minutes,
  });

  final String label;
  final int weekday;
  final int minutes;
}

class SubjectProgressData {
  SubjectProgressData({
    required this.subjectId,
    required this.name,
    required this.colorHex,
    required this.progress,
    required this.focusMinutes,
    required this.completedDeadlines,
    required this.totalDeadlines,
  });

  final int? subjectId;
  final String name;
  final String colorHex;
  final int progress;
  final int focusMinutes;
  final int completedDeadlines;
  final int totalDeadlines;
}

class AchievementData {
  AchievementData({
    required this.title,
    required this.description,
    required this.accentHex,
  });

  final String title;
  final String description;
  final String accentHex;
}
