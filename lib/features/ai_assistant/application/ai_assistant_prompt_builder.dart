import '../../deadlines/data/deadline_model.dart';
import '../../pomodoro/data/pomodoro_session_model.dart';
import '../../schedule/data/schedule_model.dart';
import '../../study_plan/data/study_plan_model.dart';
import '../data/ai_study_context.dart';

enum AiAssistantIntent {
  general,
  tomorrowSchedule,
  tonightPlan,
  weeklySummary,
  priority,
}

class AiAssistantPromptBuilder {
  const AiAssistantPromptBuilder._();

  static AiAssistantIntent detectIntent(String rawMessage) {
    final String message = rawMessage.toLowerCase();
    if (RegExp(r'\b(ngay mai|mai|ngày mai|hom mai|hôm mai)\b')
            .hasMatch(message) &&
        RegExp(r'\b(lich|hoc|học|schedule)\b').hasMatch(message)) {
      return AiAssistantIntent.tomorrowSchedule;
    }
    if (RegExp(r'\b(toi nay|tối nay|toi nay|tonight|evening)\b')
            .hasMatch(message) ||
        RegExp(r'\b(hoc gi|học gì|nên học|nen hoc|should study|study tonight)\b')
            .hasMatch(message)) {
      return AiAssistantIntent.tonightPlan;
    }
    if (RegExp(
            r'\b(tuan nay|tuần nay|tum tat|tom tat|tong quan|tổng quan|summary|weekly)\b')
        .hasMatch(message)) {
      return AiAssistantIntent.weeklySummary;
    }
    if (RegExp(r'\b(uu tien|ưu tiên|can chu y|cần chú ý|quan trong nhat|quan trọng nhất|priority|urgent)\b')
            .hasMatch(message) ||
        RegExp(r'\b(mon nao|mon gi|môn nào|môn gì|subject)\b')
            .hasMatch(message)) {
      return AiAssistantIntent.priority;
    }
    return AiAssistantIntent.general;
  }

  static String intentLabel(AiAssistantIntent intent) {
    switch (intent) {
      case AiAssistantIntent.tomorrowSchedule:
        return 'lịch học và kế hoạch cho ngày mai';
      case AiAssistantIntent.tonightPlan:
        return 'nên học gì tối nay';
      case AiAssistantIntent.weeklySummary:
        return 'tổng quan học tập tuần này';
      case AiAssistantIntent.priority:
        return 'ưu tiên quan trọng nhất hiện tại';
      case AiAssistantIntent.general:
      default:
        return 'trả lời chung dựa trên dữ liệu học tập';
    }
  }

  static String buildStudyContext(
    AiStudyContext context, {
    AiAssistantIntent intent = AiAssistantIntent.general,
  }) {
    final DateTime today = context.generatedAt;
    final DateTime tomorrow = today.add(const Duration(days: 1));
    final StringBuffer buffer = StringBuffer()
      ..writeln('Nhiệm vụ trả lời: ${intentLabel(intent)}')
      ..writeln(
          'Luôn trả lời bằng tiếng Việt, dựa trên dữ liệu cung cấp, và không bịa đặt.')
      ..writeln('Nếu dữ liệu không đủ, hãy nói rõ phần nào thiếu.')
      ..writeln('Trả lời ngắn gọn, cụ thể và hữu ích.')
      ..writeln('')
      ..writeln('Tóm tắt dữ liệu:')
      ..writeln('- Người dùng: ${context.displayName}')
      ..writeln('- Deadline quá hạn: ${context.overdueDeadlines.length}')
      ..writeln('- Deadline sắp tới: ${context.upcomingDeadlines.length}')
      ..writeln('- Lịch học hôm nay: ${context.schedulesForDate(today).length}')
      ..writeln(
          '- Lịch học ngày mai: ${context.schedulesForDate(tomorrow).length}')
      ..writeln('- Kế hoạch hôm nay: ${context.plansForDate(today).length}')
      ..writeln('- Kế hoạch ngày mai: ${context.plansForDate(tomorrow).length}')
      ..writeln(
          '- Pomodoro hôm nay: ${_formatMinutes(context.focusMinutesForDate(today))}')
      ..writeln('- Ghi chú hiện có: ${context.notes.length}')
      ..writeln('');

    // Intent-aware sections
    switch (intent) {
      case AiAssistantIntent.tomorrowSchedule:
        _addTomorrowScheduleSection(buffer, context);
        break;
      case AiAssistantIntent.tonightPlan:
        _addTonightPlanSections(buffer, context);
        break;
      case AiAssistantIntent.weeklySummary:
        _addWeeklySummarySections(buffer, context);
        break;
      case AiAssistantIntent.priority:
        _addPrioritySections(buffer, context);
        break;
      case AiAssistantIntent.general:
      default:
        _addGeneralSections(buffer, context);
        break;
    }

    return buffer.toString().trim();
  }

  static void _addTomorrowScheduleSection(
      StringBuffer buffer, AiStudyContext context) {
    final DateTime tomorrow = context.generatedAt.add(const Duration(days: 1));
    final List<ScheduleModel> tomorrowSchedules =
        context.schedulesForDate(tomorrow);
    final List<StudyPlanModel> tomorrowPlans = context.plansForDate(tomorrow);

    buffer
      ..writeln('Ngày mai:')
      ..writeln('Lịch học:')
      ..writeln(_scheduleSection(tomorrowSchedules,
          emptyMessage: '- Không có lịch học ngày mai.'))
      ..writeln('Kế hoạch học:')
      ..writeln(_planSection(tomorrowPlans,
          emptyMessage: '- Không có kế hoạch học ngày mai.'));
  }

  static void _addTonightPlanSections(
      StringBuffer buffer, AiStudyContext context) {
    final DateTime today = context.generatedAt;
    final DateTime tomorrow = today.add(const Duration(days: 1));
    final List<DeadlineModel> overdue = context.overdueDeadlines;
    final List<DeadlineModel> urgent = context.upcomingDeadlines
        .where((DeadlineModel item) => item.dueAt.difference(today).inDays <= 2)
        .toList(growable: false);
    final List<ScheduleModel> tomorrowSchedules =
        context.schedulesForDate(tomorrow);
    final List<StudyPlanModel> tomorrowPlans = context.plansForDate(tomorrow);

    buffer
      ..writeln('Deadline quá hạn:')
      ..writeln(_deadlineSection(overdue.take(3).toList(growable: false),
          emptyMessage: '- Không có deadline quá hạn.'))
      ..writeln('')
      ..writeln('Deadline sắp tới (2 ngày):')
      ..writeln(_deadlineSection(urgent.take(3).toList(growable: false),
          emptyMessage: '- Không có deadline sắp tới trong 2 ngày.'))
      ..writeln('')
      ..writeln('Ngày mai:')
      ..writeln('Lịch học:')
      ..writeln(_scheduleSection(tomorrowSchedules,
          emptyMessage: '- Không có lịch học ngày mai.'))
      ..writeln('Kế hoạch học:')
      ..writeln(_planSection(tomorrowPlans,
          emptyMessage: '- Không có kế hoạch học ngày mai.'))
      ..writeln('')
      ..writeln('Pomodoro hôm nay:')
      ..writeln(_pomodoroSection(
          context.sessions
              .where((PomodoroSessionModel item) =>
                  AiStudyContext.isSameDate(item.sessionDate, today) &&
                  item.type.toLowerCase() == 'focus')
              .toList(growable: false),
          emptyMessage: '- Không có phiên Pomodoro hôm nay.'));
  }

  static void _addWeeklySummarySections(
      StringBuffer buffer, AiStudyContext context) {
    final DateTime today = context.generatedAt;
    final List<DeadlineModel> nextWeekDeadlines =
        context.upcomingDeadlines.where((DeadlineModel item) {
      final DateTime due = item.dueAt;
      return !AiStudyContext.isSameDate(due, today) &&
          due.isBefore(today.add(const Duration(days: 7)));
    }).toList(growable: false);

    buffer
      ..writeln('Tuần này:')
      ..writeln('Lịch học:')
      ..writeln(_weeklyScheduleSection(context))
      ..writeln('Kế hoạch học:')
      ..writeln(_planSection(
          context.plansForCurrentWeek().take(5).toList(growable: false),
          emptyMessage: '- Không có kế hoạch học tuần này.'))
      ..writeln('')
      ..writeln('Deadline trong tuần này:')
      ..writeln(_deadlineSection(
          nextWeekDeadlines.take(5).toList(growable: false),
          emptyMessage: '- Không có deadline trong tuần này.'))
      ..writeln('')
      ..writeln('Pomodoro tuần này:')
      ..writeln(
          '- Tổng thời gian: ${_formatMinutes(context.focusMinutesThisWeek())}');
  }

  static void _addPrioritySections(
      StringBuffer buffer, AiStudyContext context) {
    final List<DeadlineModel> overdue = context.overdueDeadlines;
    final List<DeadlineModel> urgent = context.upcomingDeadlines
        .where((DeadlineModel item) =>
            item.dueAt.difference(context.generatedAt).inDays <= 3)
        .toList(growable: false);
    final List<ScheduleModel> todaySchedules =
        context.schedulesForDate(context.generatedAt);

    buffer
      ..writeln('Deadline quá hạn:')
      ..writeln(_deadlineSection(overdue.take(3).toList(growable: false),
          emptyMessage: '- Không có deadline quá hạn.'))
      ..writeln('')
      ..writeln('Deadline sắp tới (3 ngày):')
      ..writeln(_deadlineSection(urgent.take(3).toList(growable: false),
          emptyMessage: '- Không có deadline sắp tới trong 3 ngày.'))
      ..writeln('')
      ..writeln('Hôm nay:')
      ..writeln('Lịch học:')
      ..writeln(_scheduleSection(todaySchedules,
          emptyMessage: '- Không có lịch học hôm nay.'));
  }

  static void _addGeneralSections(StringBuffer buffer, AiStudyContext context) {
    final DateTime today = context.generatedAt;
    final DateTime tomorrow = today.add(const Duration(days: 1));
    final List<ScheduleModel> todaySchedules = context.schedulesForDate(today);
    final List<ScheduleModel> tomorrowSchedules =
        context.schedulesForDate(tomorrow);
    final List<StudyPlanModel> todayPlans = context.plansForDate(today);
    final List<StudyPlanModel> tomorrowPlans = context.plansForDate(tomorrow);
    final List<PomodoroSessionModel> todayPomodoros = context.sessions
        .where((PomodoroSessionModel item) =>
            AiStudyContext.isSameDate(item.sessionDate, today) &&
            item.type.toLowerCase() == 'focus')
        .toList(growable: false);

    buffer
      ..writeln('Hôm nay:')
      ..writeln('Lịch học:')
      ..writeln(_scheduleSection(todaySchedules,
          emptyMessage: '- Không có lịch học hôm nay.'))
      ..writeln('Kế hoạch học:')
      ..writeln(_planSection(todayPlans,
          emptyMessage: '- Không có kế hoạch học hôm nay.'))
      ..writeln('Pomodoro hôm nay:')
      ..writeln(_pomodoroSection(todayPomodoros,
          emptyMessage: '- Không có phiên Pomodoro hôm nay.'))
      ..writeln('')
      ..writeln('Ngày mai:')
      ..writeln('Lịch học:')
      ..writeln(_scheduleSection(tomorrowSchedules,
          emptyMessage: '- Không có lịch học ngày mai.'))
      ..writeln('Kế hoạch học:')
      ..writeln(_planSection(tomorrowPlans,
          emptyMessage: '- Không có kế hoạch học ngày mai.'))
      ..writeln('')
      ..writeln('Deadline quá hạn:')
      ..writeln(_deadlineSection(
          context.overdueDeadlines.take(3).toList(growable: false),
          emptyMessage: '- Không có deadline quá hạn.'))
      ..writeln('')
      ..writeln('Deadline sắp tới:')
      ..writeln(_deadlineSection(
          context.upcomingDeadlines.take(3).toList(growable: false),
          emptyMessage: '- Không có deadline sắp tới.'));
  }

  static String _weeklyScheduleSection(AiStudyContext context) {
    final DateTime today = context.generatedAt;
    final List<String> days = <String>[
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật'
    ];
    final List<String> lines = <String>[];

    for (int i = 0; i < 7; i++) {
      final DateTime date = today.add(Duration(days: i));
      final List<ScheduleModel> schedules = context.schedulesForDate(date);
      if (schedules.isNotEmpty) {
        lines.add(
            '- ${days[date.weekday - 1]} (${date.day}/${date.month}): ${schedules.length} lịch học');
      }
    }

    return lines.isEmpty ? '- Không có lịch học tuần này.' : lines.join('\n');
  }

  static String _deadlineSection(
    List<DeadlineModel> deadlines, {
    required String emptyMessage,
  }) {
    if (deadlines.isEmpty) {
      return emptyMessage;
    }

    return deadlines.map((DeadlineModel item) {
      final String subject = item.subjectName?.trim().isNotEmpty == true
          ? item.subjectName!.trim()
          : 'Chưa gắn môn';
      final String description = item.description.trim().isEmpty
          ? ''
          : ' | Mô tả: ${_shorten(item.description.trim(), 120)}';
      final String dueTime = item.dueTime?.trim().isNotEmpty == true
          ? ' ${item.dueTime!.trim()}'
          : '';
      final String status = item.isOverdue ? 'quá hạn' : 'sắp tới';
      return '- ${item.title} | Môn: $subject | Hạn: ${item.dueDate.toIso8601String().split('T').first}$dueTime | Tiến độ: ${item.progress}% | $status$description';
    }).join('\n');
  }

  static String _scheduleSection(
    List<ScheduleModel> schedules, {
    required String emptyMessage,
  }) {
    if (schedules.isEmpty) {
      return emptyMessage;
    }

    return schedules.map((ScheduleModel item) {
      final String subject = item.subjectName?.trim().isNotEmpty == true
          ? item.subjectName!.trim()
          : 'Chưa gắn môn';
      final String room =
          item.room.trim().isEmpty ? 'Chưa có phòng' : item.room.trim();
      final String type =
          item.type.trim().isEmpty ? 'Chưa có loại' : item.type.trim();
      return '- $subject | ${item.timeRange} | $room | $type';
    }).join('\n');
  }

  static String _planSection(
    List<StudyPlanModel> plans, {
    required String emptyMessage,
  }) {
    if (plans.isEmpty) {
      return emptyMessage;
    }

    return plans.map((StudyPlanModel item) {
      final String subject = item.subjectName?.trim().isNotEmpty == true
          ? item.subjectName!.trim()
          : 'Chưa gắn môn';
      final String topic = item.topic.trim().isEmpty
          ? 'Không ghi chủ đề'
          : _shorten(item.topic.trim(), 100);
      return '- ${item.title} | Môn: $subject | Ngày: ${item.planDate.toIso8601String().split('T').first} | Khung giờ: ${item.timeLabel} | Trạng thái: ${item.status} | Chủ đề: $topic';
    }).join('\n');
  }

  static String _pomodoroSection(
    List<PomodoroSessionModel> sessions, {
    required String emptyMessage,
  }) {
    if (sessions.isEmpty) {
      return emptyMessage;
    }

    return sessions.map((PomodoroSessionModel item) {
      final String subject = item.subjectName?.trim().isNotEmpty == true
          ? item.subjectName!.trim()
          : 'Không gắn môn';
      final String completedAt =
          item.completedAt?.toIso8601String() ?? 'Chưa hoàn tất';
      return '- ${item.type} | $subject | ${item.duration} phút | ${item.sessionDate.toIso8601String().split('T').first} | $completedAt';
    }).join('\n');
  }

  static String _shorten(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength - 1)}…';
  }

  static String _formatMinutes(int value) {
    if (value <= 0) {
      return '0 phút';
    }
    final int hours = value ~/ 60;
    final int minutes = value % 60;
    if (hours == 0) {
      return '$minutes phút';
    }
    if (minutes == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $minutes phút';
  }
}
