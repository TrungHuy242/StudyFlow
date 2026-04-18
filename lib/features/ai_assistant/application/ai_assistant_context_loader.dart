import 'dart:developer' as developer;

import '../../auth/application/app_session_controller.dart';
import '../../deadlines/data/deadline_model.dart';
import '../../deadlines/data/deadline_repository.dart';
import '../../notes/data/note_model.dart';
import '../../notes/data/note_repository.dart';
import '../../pomodoro/data/pomodoro_repository.dart';
import '../../pomodoro/data/pomodoro_session_model.dart';
import '../../schedule/data/schedule_model.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../study_plan/data/study_plan_model.dart';
import '../../study_plan/data/study_plan_repository.dart';
import '../data/ai_study_context.dart';

class AiAssistantContextLoader {
  const AiAssistantContextLoader({
    required this.deadlineRepository,
    required this.scheduleRepository,
    required this.studyPlanRepository,
    required this.pomodoroRepository,
    required this.noteRepository,
    required this.sessionController,
  });

  static const String _logName = 'AiAssistantContextLoader';

  final DeadlineRepository deadlineRepository;
  final ScheduleRepository scheduleRepository;
  final StudyPlanRepository studyPlanRepository;
  final PomodoroRepository pomodoroRepository;
  final NoteRepository noteRepository;
  final AppSessionController sessionController;

  Future<AiAssistantContextLoadResult> load() async {
    developer.log('Starting AI study context load.', name: _logName);

    if (!sessionController.isLoggedIn) {
      developer.log(
        'No authenticated app session. Returning empty AI context.',
        name: _logName,
      );
      return AiAssistantContextLoadResult(
        context: buildFallbackContext(),
        warnings: const <String>[
          'Bạn chưa đăng nhập đầy đủ nên trợ lý chỉ mở ở chế độ giới hạn.',
        ],
      );
    }

    final List<String> warnings = <String>[];

    final List<DeadlineModel> deadlines = await _loadSection<DeadlineModel>(
      label: 'deadlines',
      loader: deadlineRepository.getDeadlines,
      warnings: warnings,
      userMessage:
          'Không tải được deadline. Trợ lý sẽ tiếp tục với dữ liệu còn lại.',
    );

    final List<ScheduleModel> schedules = await _loadSection<ScheduleModel>(
      label: 'schedules',
      loader: scheduleRepository.getSchedules,
      warnings: warnings,
      userMessage:
          'Không tải được lịch học. Trợ lý sẽ tiếp tục với dữ liệu còn lại.',
    );

    final List<StudyPlanModel> plans = await _loadSection<StudyPlanModel>(
      label: 'study_plans',
      loader: studyPlanRepository.getPlans,
      warnings: warnings,
      userMessage:
          'Không tải được kế hoạch học tập. Trợ lý sẽ tiếp tục với dữ liệu còn lại.',
    );

    final List<PomodoroSessionModel> sessions =
        await _loadSection<PomodoroSessionModel>(
      label: 'pomodoro_sessions',
      loader: pomodoroRepository.getSessions,
      warnings: warnings,
      userMessage:
          'Không tải được lịch sử Pomodoro. Trợ lý sẽ tiếp tục với dữ liệu còn lại.',
    );

    final List<NoteModel> notes = await _loadSection<NoteModel>(
      label: 'notes',
      loader: noteRepository.getNotes,
      warnings: warnings,
      userMessage:
          'Không tải được ghi chú. Trợ lý sẽ tiếp tục với dữ liệu còn lại.',
    );

    final AiStudyContext context = buildFallbackContext(
      deadlines: deadlines,
      schedules: schedules,
      plans: plans,
      sessions: sessions,
      notes: notes,
    );

    developer.log(
      'AI study context load completed: deadlines=${deadlines.length}, '
      'schedules=${schedules.length}, plans=${plans.length}, '
      'sessions=${sessions.length}, notes=${notes.length}.',
      name: _logName,
    );

    return AiAssistantContextLoadResult(
      context: context,
      warnings: _dedupeWarnings(warnings),
    );
  }

  AiStudyContext buildFallbackContext({
    List<DeadlineModel> deadlines = const <DeadlineModel>[],
    List<ScheduleModel> schedules = const <ScheduleModel>[],
    List<StudyPlanModel> plans = const <StudyPlanModel>[],
    List<PomodoroSessionModel> sessions = const <PomodoroSessionModel>[],
    List<NoteModel> notes = const <NoteModel>[],
  }) {
    final String rawDisplayName =
        sessionController.settings?.displayName.trim() ?? '';

    return AiStudyContext(
      displayName: rawDisplayName.isEmpty ? 'bạn' : rawDisplayName,
      studyGoalMinutes: sessionController.settings?.studyGoalMinutes ?? 120,
      focusDurationMinutes: sessionController.settings?.focusDuration ?? 25,
      shortBreakMinutes: sessionController.settings?.shortBreakDuration ?? 5,
      generatedAt: DateTime.now(),
      deadlines: List<DeadlineModel>.unmodifiable(deadlines),
      schedules: List<ScheduleModel>.unmodifiable(schedules),
      plans: List<StudyPlanModel>.unmodifiable(plans),
      sessions: List<PomodoroSessionModel>.unmodifiable(sessions),
      notes: List<NoteModel>.unmodifiable(notes),
    );
  }

  Future<List<T>> _loadSection<T>({
    required String label,
    required Future<List<T>> Function() loader,
    required List<String> warnings,
    required String userMessage,
  }) async {
    try {
      final List<T> items = await loader();
      developer.log(
        'Loaded $label successfully (${items.length} items).',
        name: _logName,
      );
      return items;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load $label for AI context.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      warnings.add(userMessage);
      return <T>[];
    }
  }

  List<String> _dedupeWarnings(List<String> warnings) {
    final List<String> unique = <String>[];
    for (final String warning in warnings) {
      if (!unique.contains(warning)) {
        unique.add(warning);
      }
    }
    return unique;
  }
}

class AiAssistantContextLoadResult {
  const AiAssistantContextLoadResult({
    required this.context,
    this.warnings = const <String>[],
  });

  final AiStudyContext context;
  final List<String> warnings;
}
