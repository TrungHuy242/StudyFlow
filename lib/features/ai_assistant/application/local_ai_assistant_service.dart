import '../../deadlines/data/deadline_model.dart';
import '../../schedule/data/schedule_model.dart';
import '../../study_plan/data/study_plan_model.dart';
import '../data/ai_assistant_message.dart';
import '../data/ai_study_context.dart';
import 'ai_assistant_prompt_builder.dart';
import 'ai_assistant_service.dart';

class LocalAiAssistantService extends AiAssistantService {
  const LocalAiAssistantService();

  @override
  String buildWelcomeMessage(AiStudyContext context) {
    if (!context.hasAnyData) {
      return 'Mình chưa thấy nhiều dữ liệu học tập trong tài khoản hiện tại. '
          'Bạn có thể thêm deadline, lịch học, kế hoạch hoặc phiên Pomodoro rồi hỏi lại để mình gợi ý chính xác hơn.';
    }

    final int todayFocus = context.focusMinutesForDate(context.generatedAt);
    final int weekFocus = context.focusMinutesThisWeek();
    final int openDeadlines = context.openDeadlines.length;
    final int overdueDeadlines = context.overdueDeadlines.length;

    return 'Mình đã đọc dữ liệu học tập hiện tại của ${context.displayName}. '
        'Hiện có $openDeadlines deadline mở, $overdueDeadlines deadline quá hạn, '
        '${_formatMinutes(todayFocus)} học hôm nay và ${_formatMinutes(weekFocus)} trong tuần này. '
        'Bạn có thể chọn một gợi ý bên dưới hoặc hỏi tự do.';
  }

  @override
  Future<String> reply({
    required String message,
    required AiStudyContext context,
    List<AiAssistantMessage> history = const <AiAssistantMessage>[],
  }) async {
    final String normalized = _normalize(message);
    final AiAssistantIntent intent =
        AiAssistantPromptBuilder.detectIntent(normalized);

    if (!context.hasAnyData) {
      return 'Hiện chưa có đủ dữ liệu để phân tích sâu. '
          'Thêm deadline, lịch học, kế hoạch hoặc ghi chú để mình có căn cứ để tư vấn chính xác hơn.';
    }

    // Check if this is a follow-up question by looking at history
    final bool isFollowUp = history.isNotEmpty && history.length >= 2;
    final String previousResponse =
        isFollowUp ? history[history.length - 2].text : '';

    switch (intent) {
      case AiAssistantIntent.tomorrowSchedule:
        return _buildTomorrowSchedule(context);
      case AiAssistantIntent.tonightPlan:
        return _buildTonightPlan(context);
      case AiAssistantIntent.weeklySummary:
        return _buildWeeklySummary(context);
      case AiAssistantIntent.priority:
        return _buildTodayPriority(context);
      case AiAssistantIntent.general:
      default:
        // If it looks like a follow-up, try to understand context
        if (isFollowUp && previousResponse.contains('môn')) {
          return _buildGeneralAnswerWithContext(context, previousResponse);
        }
        return _buildGeneralAnswer(context);
    }
  }

  String _buildTomorrowSchedule(AiStudyContext context) {
    final DateTime tomorrow = context.generatedAt.add(const Duration(days: 1));
    final List<ScheduleModel> schedules = context.schedulesForDate(tomorrow);
    final List<StudyPlanModel> plans = context.plansForDate(tomorrow);
    final List<String> lines = <String>[];

    if (schedules.isEmpty && plans.isEmpty) {
      lines.add('Ngày mai bạn không có lịch học hay kế hoạch nào.');
      return lines.join('\n');
    }

    if (schedules.isNotEmpty) {
      lines.add('Ngày mai bạn có ${schedules.length} lịch học:');
      for (final ScheduleModel item in schedules) {
        final String room = item.room.isEmpty ? '' : ' tại ${item.room}';
        lines.add(
            '• ${_subjectLabel(item.subjectName)} lúc ${item.timeRange}$room');
      }
    }

    if (plans.isNotEmpty) {
      if (schedules.isNotEmpty) lines.add('');
      lines.add('Kế hoạch học ngày mai:');
      for (final StudyPlanModel item in plans.take(3)) {
        final String topic = item.topic.isEmpty ? '' : ' - ${item.topic}';
        lines.add('• ${item.title} (${_subjectLabel(item.subjectName)})$topic');
      }
    }

    return lines.join('\n');
  }

  String _buildTodayPriority(AiStudyContext context) {
    final List<String> lines = <String>[];
    final List<DeadlineModel> overdue = context.overdueDeadlines;
    final List<DeadlineModel> urgent = context.upcomingDeadlines
        .where((DeadlineModel item) =>
            item.dueAt.difference(DateTime.now()).inDays <= 2)
        .take(3)
        .toList(growable: false);
    final List<ScheduleModel> todaySchedule =
        context.schedulesForDate(context.generatedAt);
    final int goalLeft = (context.studyGoalMinutes -
            context.focusMinutesForDate(context.generatedAt))
        .clamp(0, context.studyGoalMinutes);

    lines.add('🎯 Ưu tiên hôm nay:');
    lines.add('');

    if (overdue.isNotEmpty) {
      lines.add('🔴 Xử lý ngay (quá hạn):');
      for (final DeadlineModel item in overdue.take(2)) {
        lines.add(
            '  • ${item.title} (${_subjectLabel(item.subjectName)}) - ${item.progress}% xong');
      }
    } else if (urgent.isNotEmpty) {
      lines.add('🟠 Deadline sắp hết hạn:');
      for (final DeadlineModel item in urgent.take(2)) {
        lines.add(
            '  • ${item.title} (${_subjectLabel(item.subjectName)}) - ${_relativeDeadlineLabel(item)}');
      }
    } else if (todaySchedule.isNotEmpty) {
      lines.add('📅 Chuẩn bị lịch học hôm nay:');
      for (final ScheduleModel item in todaySchedule.take(2)) {
        lines.add(
            '  • ${_subjectLabel(item.subjectName)} lúc ${item.timeRange}');
      }
    } else {
      lines.add('💪 Chưa có deadline cấp bách - tập trung vào các môn yếu');
    }

    lines.add('');
    if (goalLeft > 0) {
      lines.add('⏱️  Còn ${_formatMinutes(goalLeft)} để đạt mục tiêu hôm nay');
    } else {
      lines.add('✅ Đã đạt mục tiêu hôm nay');
    }

    return lines.join('\n');
  }

  String _buildTonightPlan(AiStudyContext context) {
    final List<_SubjectUrgency> ranked = _rankSubjects(context);
    final int todayFocus = context.focusMinutesForDate(context.generatedAt);
    final int remaining = context.studyGoalMinutes > todayFocus
        ? context.studyGoalMinutes - todayFocus
        : context.focusDurationMinutes * 2;
    final int blockCount =
        (remaining / context.focusDurationMinutes).ceil().clamp(2, 4);

    if (ranked.isEmpty) {
      return 'Tối nay bạn có thể học ${blockCount * context.focusDurationMinutes} phút '
          'chia thành $blockCount phiên Pomodoro.';
    }

    final List<String> lines = <String>[
      'Kế hoạch tối nay (${blockCount * context.focusDurationMinutes} phút):',
      '',
    ];

    for (int index = 0; index < blockCount; index++) {
      final _SubjectUrgency target = ranked[index % ranked.length];
      final String priorityLabel = index == 0 ? '🔴 Ưu tiên' : '🟠 Tiếp theo';
      lines.add(
          '$priorityLabel: ${target.subject} (${context.focusDurationMinutes} phút)');
    }

    final List<ScheduleModel> tomorrowSchedule = context
        .schedulesForDate(context.generatedAt.add(const Duration(days: 1)));
    if (tomorrowSchedule.isNotEmpty) {
      lines.add('');
      lines.add(
          '💡 Gợi ý: Dành 5 phút cuối xem lại lịch ngày mai (${_subjectLabel(tomorrowSchedule.first.subjectName)})');
    }

    return lines.join('\n');
  }

  String _buildWeeklySummary(AiStudyContext context) {
    final int weekFocus = context.focusMinutesThisWeek();
    final List<StudyPlanModel> weekPlans = context.plansForCurrentWeek();
    final int completedPlans = weekPlans.where(_isCompletedPlan).length;
    final int openDeadlines = context.openDeadlines.length;
    final int overdue = context.overdueDeadlines.length;
    final int upcomingWeek = context.upcomingDeadlines
        .where((DeadlineModel item) =>
            item.dueAt.difference(DateTime.now()).inDays <= 7)
        .length;

    final List<String> lines = <String>[
      'Tình hình học tập tuần này:',
      '',
      'Thời gian: ${_formatMinutes(weekFocus)} làm việc tập trung',
      'Kế hoạch: ${weekPlans.length} mục (${completedPlans} hoàn thành)',
      'Deadline: $openDeadlines đang mở',
    ];

    if (overdue > 0) {
      lines.add('⚠️ $overdue deadline quá hạn cần xử lý');
    }

    if (upcomingWeek > 0) {
      lines.add('📅 $upcomingWeek deadline sắp hết hạn trong 7 ngày');
    }

    if (context.notes.isNotEmpty) {
      lines.add('📝 ${context.notes.length} ghi chú');
    }

    return lines.join('\n');
  }

  String _buildGeneralAnswer(AiStudyContext context) {
    final List<_SubjectUrgency> ranked = _rankSubjects(context);
    final String topSubject = ranked.isEmpty
        ? 'chưa xác định được môn ưu tiên'
        : ranked.first.subject;
    final int todayFocus = context.focusMinutesForDate(context.generatedAt);
    final int overdue = context.overdueDeadlines.length;
    final int todayPlans = context.plansForDate(context.generatedAt).length;
    final List<ScheduleModel> todaySchedules =
        context.schedulesForDate(context.generatedAt);
    final List<DeadlineModel> upcoming =
        context.upcomingDeadlines.take(2).toList();

    final List<String> lines = <String>[
      'Tổng quan cho ${context.displayName}:',
      '- Môn cần chú ý nhất hiện tại: $topSubject.',
    ];

    if (overdue > 0) {
      lines.add('- Có $overdue deadline quá hạn cần xử lý ngay.');
    }
    if (todayPlans > 0) {
      lines.add('- Hôm nay có $todayPlans kế hoạch học.');
    }
    if (todaySchedules.isNotEmpty) {
      lines.add('- Hôm nay có ${todaySchedules.length} lịch học.');
    }
    lines.add('- Thời gian tập trung hôm nay: ${_formatMinutes(todayFocus)}.');

    if (upcoming.isNotEmpty) {
      lines.add(
          '- Deadline gần nhất: ${upcoming.first.title} (${_subjectLabel(upcoming.first.subjectName)}) vào ${upcoming.first.dueDate.toIso8601String().split('T').first}.');
    }

    lines.add(
        'Nếu cần, hãy hỏi cụ thể về "ngày mai" hoặc "tối nay" để mình trả lời rõ hơn.');
    return lines.join('\n');
  }

  String _buildGeneralAnswerWithContext(
      AiStudyContext context, String previousResponse) {
    // This method understands follow-up questions based on previous answers
    final List<_SubjectUrgency> ranked = _rankSubjects(context);

    // Simple context awareness: if previous mention was about a subject, provide more details
    if (ranked.isNotEmpty && previousResponse.contains('môn')) {
      final _SubjectUrgency topSubject = ranked.first;
      final List<String> lines = <String>[
        'Về ${topSubject.subject}:',
      ];

      for (final String reason in topSubject.reasons.take(2)) {
        lines.add('• $reason');
      }

      if (ranked.length > 1) {
        lines.add('\nSau đó là ${ranked[1].subject} cũng cần chú ý.');
      }

      return lines.join('\n');
    }

    // Fall back to general answer if context doesn't help
    return _buildGeneralAnswer(context);
  }

  List<_SubjectUrgency> _rankSubjects(AiStudyContext context) {
    final Map<String, double> scores = <String, double>{};
    final Map<String, List<String>> reasons = <String, List<String>>{};

    void addScore(String subject, double score, String reason) {
      if (subject.trim().isEmpty) {
        return;
      }
      scores.update(subject, (double value) => value + score,
          ifAbsent: () => score);
      reasons.putIfAbsent(subject, () => <String>[]).add(reason);
    }

    for (final DeadlineModel item in context.openDeadlines) {
      final String subject = _subjectLabel(item.subjectName);
      final int days = item.dueAt.difference(DateTime.now()).inDays;
      final double urgency =
          item.isOverdue ? 120 : (10 - days.clamp(0, 10)) * 10;
      final double progressPenalty = ((100 - item.progress).clamp(0, 100)) / 5;
      addScore(
        subject,
        urgency + progressPenalty,
        '${item.title} ${item.isOverdue ? 'đã quá hạn' : 'còn ${days.clamp(0, 30)} ngày'} với tiến độ ${item.progress}%',
      );
    }

    for (final StudyPlanModel item
        in context.plansForDate(context.generatedAt)) {
      final String subject = _subjectLabel(item.subjectName);
      addScore(
        subject,
        _isCompletedPlan(item) ? 4 : 18,
        _isCompletedPlan(item)
            ? 'đã có kế hoạch hoàn thành hôm nay'
            : 'đã có kế hoạch học hôm nay',
      );
    }

    for (final ScheduleModel item
        in context.schedulesForDate(context.generatedAt)) {
      addScore(
        _subjectLabel(item.subjectName),
        8,
        'có lịch học hôm nay lúc ${item.startTime}',
      );
    }

    final List<_SubjectUrgency> ranked = scores.entries
        .map(
          (MapEntry<String, double> entry) => _SubjectUrgency(
            subject: entry.key,
            score: entry.value,
            reasons: reasons[entry.key] ?? const <String>[],
          ),
        )
        .toList()
      ..sort(
          (_SubjectUrgency a, _SubjectUrgency b) => b.score.compareTo(a.score));
    return ranked;
  }

  bool _isCompletedPlan(StudyPlanModel item) {
    final String normalized = _normalize(item.status);
    return normalized.contains('done') || normalized.contains('complete');
  }

  String _relativeDeadlineLabel(DeadlineModel item) {
    if (item.isOverdue) {
      return 'quá hạn';
    }
    final int days = item.dueAt.difference(DateTime.now()).inDays;
    if (days <= 0) {
      return item.dueTime?.isNotEmpty == true
          ? 'hôm nay ${item.dueTime}'
          : 'hôm nay';
    }
    if (days == 1) {
      return 'ngày mai';
    }
    return 'còn $days ngày';
  }

  String _subjectLabel(String? subjectName) {
    final String value = subjectName?.trim() ?? '';
    return value.isEmpty ? 'môn chưa gắn tên' : value;
  }

  String _formatMinutes(int value) {
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

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('ắ', 'a')
        .replaceAll('ằ', 'a')
        .replaceAll('ẳ', 'a')
        .replaceAll('ẵ', 'a')
        .replaceAll('ặ', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ấ', 'a')
        .replaceAll('ầ', 'a')
        .replaceAll('ẩ', 'a')
        .replaceAll('ẫ', 'a')
        .replaceAll('ậ', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ẻ', 'e')
        .replaceAll('ẽ', 'e')
        .replaceAll('ẹ', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ế', 'e')
        .replaceAll('ề', 'e')
        .replaceAll('ể', 'e')
        .replaceAll('ễ', 'e')
        .replaceAll('ệ', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ỉ', 'i')
        .replaceAll('ĩ', 'i')
        .replaceAll('ị', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ỏ', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ọ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ố', 'o')
        .replaceAll('ồ', 'o')
        .replaceAll('ổ', 'o')
        .replaceAll('ỗ', 'o')
        .replaceAll('ộ', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ớ', 'o')
        .replaceAll('ờ', 'o')
        .replaceAll('ở', 'o')
        .replaceAll('ỡ', 'o')
        .replaceAll('ợ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ủ', 'u')
        .replaceAll('ũ', 'u')
        .replaceAll('ụ', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ứ', 'u')
        .replaceAll('ừ', 'u')
        .replaceAll('ử', 'u')
        .replaceAll('ữ', 'u')
        .replaceAll('ự', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ỳ', 'y')
        .replaceAll('ỷ', 'y')
        .replaceAll('ỹ', 'y')
        .replaceAll('ỵ', 'y')
        .replaceAll('đ', 'd');
  }
}

class _SubjectUrgency {
  const _SubjectUrgency({
    required this.subject,
    required this.score,
    required this.reasons,
  });

  final String subject;
  final double score;
  final List<String> reasons;
}
