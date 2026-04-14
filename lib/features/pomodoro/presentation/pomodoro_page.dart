import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../auth/application/app_session_controller.dart';
import '../../profile/data/user_settings_model.dart';
import '../../profile/data/user_settings_repository.dart';
import '../../profile/presentation/profile_app_settings_page.dart';
import '../../subjects/data/subject_model.dart';
import '../../subjects/data/subject_repository.dart';
import '../data/pomodoro_repository.dart';
import '../data/pomodoro_session_model.dart';
import 'pomodoro_controller.dart';
import 'pomodoro_timer_state.dart';

enum _PomodoroView {
  timer,
  history,
}

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  PomodoroController? _controller;
  SubjectRepository? _subjectRepository;
  Future<List<SubjectModel>>? _subjectsFuture;
  bool _controllerInitialized = false;
  bool _showCompletion = false;
  int _lastCompletedFocusSessions = 0;
  _PomodoroView _view = _PomodoroView.timer;

  void _ensureInitialized() {
    final DatabaseService databaseService = context.read<DatabaseService>();
    _subjectRepository ??= SubjectRepository(databaseService);
    _controller ??= PomodoroController(
      PomodoroRepository(databaseService),
      context.read<UserSettingsRepository>(),
      context.read<AppRefreshNotifier>(),
    )..addListener(_handleControllerChanged);
    _subjectsFuture ??= _subjectRepository!.getSubjects();
    if (!_controllerInitialized) {
      _controllerInitialized = true;
      _controller!.initialize();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureInitialized();
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final PomodoroController? controller = _controller;
    if (!mounted || controller == null) {
      return;
    }

    final PomodoroTimerState state = controller.state;
    final bool justCompletedFocus =
        state.completedFocusSessions > _lastCompletedFocusSessions &&
            state.isBreakPhase;
    _lastCompletedFocusSessions = state.completedFocusSessions;

    if (justCompletedFocus && !_showCompletion) {
      setState(() {
        _showCompletion = true;
        _view = _PomodoroView.timer;
      });
    }
  }

  Future<void> _reloadPomodoro() async {
    final PomodoroController? controller = _controller;
    final SubjectRepository? subjectRepository = _subjectRepository;
    if (controller == null || subjectRepository == null) {
      return;
    }

    setState(() {
      _subjectsFuture = subjectRepository.getSubjects();
      _showCompletion = false;
      _view = _PomodoroView.timer;
    });
    await controller.initialize();
    _lastCompletedFocusSessions = controller.state.completedFocusSessions;
  }

  Future<void> _openSettings() async {
    setState(() {
      _showCompletion = false;
    });
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ProfileAppSettingsPage(),
      ),
    );
    if (!mounted) {
      return;
    }
    await _reloadPomodoro();
  }

  Future<void> _handlePhaseAction(PomodoroTimerState state) async {
    final PomodoroController? controller = _controller;
    if (controller == null) {
      return;
    }

    if (state.isFocusPhase) {
      await controller.completeCurrentFocusSession();
      return;
    }

    setState(() {
      _showCompletion = false;
    });
    await controller.skipCurrentBreak();
  }

  Future<void> _handleDiscard(PomodoroTimerState state) async {
    final PomodoroController? controller = _controller;
    if (controller == null) {
      return;
    }

    setState(() {
      _showCompletion = false;
    });
    if (state.isBreakPhase) {
      await controller.skipCurrentBreak();
      return;
    }
    controller.resetCurrentPhase();
  }

  void _resumeAfterCompletion() {
    final PomodoroController? controller = _controller;
    if (controller == null) {
      return;
    }
    setState(() {
      _showCompletion = false;
    });
    controller.startOrResumeTimer();
  }

  Future<void> _endAfterCompletion() async {
    final PomodoroController? controller = _controller;
    if (controller == null) {
      return;
    }
    setState(() {
      _showCompletion = false;
    });
    await controller.skipCurrentBreak();
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    final PomodoroController? controller = _controller;
    final Future<List<SubjectModel>>? subjectsFuture = _subjectsFuture;
    final UserSettingsModel? settings =
        context.watch<AppSessionController>().settings;
    if (controller == null || subjectsFuture == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF091321),
        body: AppLoadingState(message: 'Preparing pomodoro...'),
      );
    }

    return Scaffold(
      backgroundColor: _view == _PomodoroView.history
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF091321),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, _) {
          return FutureBuilder<List<SubjectModel>>(
            future: subjectsFuture,
            builder: (
              BuildContext context,
              AsyncSnapshot<List<SubjectModel>> snapshot,
            ) {
              if (snapshot.connectionState != ConnectionState.done ||
                  controller.isLoading) {
                return const AppLoadingState(message: 'Preparing pomodoro...');
              }
              if (snapshot.hasError) {
                return AppErrorState(
                  title: 'Unable to load pomodoro',
                  message: 'Try again after your subjects finish loading.',
                  onAction: _reloadPomodoro,
                );
              }

              final List<SubjectModel> subjects =
                  snapshot.data ?? <SubjectModel>[];
              final PomodoroTimerState timerState = controller.state;
              final Widget body = _buildCurrentView(
                settings: settings,
                subjects: subjects,
                timerState: timerState,
                controller: controller,
              );

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    '${_view.name}-$_showCompletion-${timerState.phase.name}-${timerState.isRunning}-${timerState.hasStartedCurrentPhase}',
                  ),
                  child: body,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCurrentView({
    required UserSettingsModel? settings,
    required List<SubjectModel> subjects,
    required PomodoroTimerState timerState,
    required PomodoroController controller,
  }) {
    if (_view == _PomodoroView.history) {
      return _PomodoroHistoryView(
        sessions: controller.history,
        onBack: () {
          setState(() {
            _view = _PomodoroView.timer;
          });
        },
      );
    }

    if (_showCompletion) {
      return _PomodoroCompletionView(
        timerState: timerState,
        settings: settings,
        sessions: controller.history,
        onContinue: _resumeAfterCompletion,
        onEnd: _endAfterCompletion,
      );
    }

    if (timerState.isRunning || timerState.canResume) {
      return _PomodoroActiveView(
        timerState: timerState,
        selectedSubjectName:
            _subjectNameFor(timerState.selectedSubjectId, subjects),
        remainingTimeLabel: controller.formatRemainingTime(),
        onPrimary: controller.handlePrimaryAction,
        onReset: controller.resetCurrentPhase,
        onSecondary:
            timerState.isFocusPhase && timerState.hasStartedCurrentPhase
                ? () => _handlePhaseAction(timerState)
                : timerState.isBreakPhase
                    ? () => _handlePhaseAction(timerState)
                    : null,
        onDiscard: () => _handleDiscard(timerState),
      );
    }

    return _PomodoroIdleView(
      settings: settings,
      timerState: timerState,
      subjects: subjects,
      onSelectSubject: (int? subjectId) {
        controller.selectSubject(
          timerState.selectedSubjectId == subjectId ? null : subjectId,
        );
      },
      onStart: controller.handlePrimaryAction,
      onHistory: () {
        setState(() {
          _showCompletion = false;
          _view = _PomodoroView.history;
        });
      },
      onSettings: _openSettings,
    );
  }
}

class _PomodoroIdleView extends StatelessWidget {
  const _PomodoroIdleView({
    required this.settings,
    required this.timerState,
    required this.subjects,
    required this.onSelectSubject,
    required this.onStart,
    required this.onHistory,
    required this.onSettings,
  });

  final UserSettingsModel? settings;
  final PomodoroTimerState timerState;
  final List<SubjectModel> subjects;
  final ValueChanged<int?> onSelectSubject;
  final VoidCallback onStart;
  final VoidCallback onHistory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final int focusMinutes =
        settings?.focusDuration ?? timerState.totalSeconds ~/ 60;
    final int breakMinutes = settings?.shortBreakDuration ?? 5;
    final int completedInCycle = _completedInCycle(timerState);
    final int totalCycleMinutes = focusMinutes * 4;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0B1424),
            Color(0xFF08101D),
            Color(0xFF070C15),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: <Widget>[
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Focus Timer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$focusMinutes phút tập trung, $breakMinutes phút nghỉ',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 34),
            Center(
              child: _PomodoroRing(
                size: 250,
                progress: 0.08,
                colors: const <Color>[
                  Color(0xFF60A5FA),
                  Color(0xFF2563EB),
                ],
                backgroundColor: const Color(0xFF132338),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$focusMinutes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'phút',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                const Expanded(
                  child: _DarkMetricCard(
                    value: '4',
                    label: 'Phiên',
                    valueColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DarkMetricCard(
                    value: '$completedInCycle/4',
                    label: 'Hoàn thành',
                    valueColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DarkMetricCard(
                    value: _formatMinutesStat(totalCycleMinutes),
                    label: 'Tổng thời gian',
                    valueColor: const Color(0xFFFBBF24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Center(
              child: Text(
                'Chọn môn học (tùy chọn)',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SubjectChipGrid(
              subjects: subjects,
              selectedSubjectId: timerState.selectedSubjectId,
              onSelectSubject: onSelectSubject,
            ),
            const SizedBox(height: 28),
            StudyFlowGradientButton(
              label: 'Bắt đầu',
              onTap: onStart,
              height: 58,
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  Color(0xFF60A5FA),
                  Color(0xFF2563EB),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _GhostActionButton(
                    icon: Icons.history_rounded,
                    label: 'Lịch sử',
                    onTap: onHistory,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _GhostActionButton(
                    icon: Icons.tune_rounded,
                    label: 'Cài đặt',
                    onTap: onSettings,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PomodoroActiveView extends StatelessWidget {
  const _PomodoroActiveView({
    required this.timerState,
    required this.selectedSubjectName,
    required this.remainingTimeLabel,
    required this.onPrimary,
    required this.onReset,
    required this.onSecondary,
    required this.onDiscard,
  });

  final PomodoroTimerState timerState;
  final String? selectedSubjectName;
  final String remainingTimeLabel;
  final VoidCallback onPrimary;
  final VoidCallback onReset;
  final VoidCallback? onSecondary;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final bool paused = !timerState.isRunning;
    final String title = paused
        ? (timerState.isFocusPhase ? 'Tạm dừng' : 'Tạm dừng nghỉ')
        : (timerState.isFocusPhase
            ? 'Đang tập trung'
            : _breakTitle(timerState.phase));
    final String sessionLabel = 'Phiên ${_sessionNumber(timerState)}/4';
    final String hint = paused
        ? 'Nhấn play để tiếp tục phiên học tập'
        : 'Mẹo: Tập trung vào một công việc duy nhất để đạt hiệu quả cao nhất';
    final String subtitle = paused
        ? 'đã tạm dừng'
        : (timerState.isFocusPhase ? 'còn lại' : 'thời gian nghỉ');
    final Color accent = paused
        ? const Color(0xFFFBBF24)
        : timerState.isFocusPhase
            ? const Color(0xFF60A5FA)
            : const Color(0xFF34D399);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: paused
              ? const <Color>[
                  Color(0xFF141C2E),
                  Color(0xFF0E1523),
                  Color(0xFF090E17),
                ]
              : timerState.isFocusPhase
                  ? const <Color>[
                      Color(0xFF0B1424),
                      Color(0xFF08101D),
                      Color(0xFF070C15),
                    ]
                  : const <Color>[
                      Color(0xFF0B1C1A),
                      Color(0xFF0A1614),
                      Color(0xFF08110F),
                    ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sessionLabel,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (selectedSubjectName != null &&
                  timerState.isFocusPhase) ...<Widget>[
                const SizedBox(height: 26),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF172B43),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF21476A)),
                  ),
                  child: Text(
                    selectedSubjectName!,
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 26),
              const Spacer(),
              _PomodoroRing(
                size: 290,
                progress: math.max(timerState.progress, 0.02),
                colors: <Color>[
                  accent.withValues(alpha: 0.7),
                  accent,
                ],
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      remainingTimeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _RoundTimerAction(
                    icon: timerState.isFocusPhase
                        ? Icons.refresh_rounded
                        : Icons.skip_next_rounded,
                    label: timerState.isFocusPhase ? 'Reset' : 'Bỏ nghỉ',
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    onTap: onReset,
                  ),
                  const SizedBox(width: 18),
                  _RoundTimerAction(
                    icon:
                        paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    label: paused ? 'Tiếp tục' : 'Tạm dừng',
                    size: 86,
                    iconSize: 38,
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    onTap: onPrimary,
                  ),
                  const SizedBox(width: 18),
                  _RoundTimerAction(
                    icon: timerState.isFocusPhase
                        ? Icons.check_rounded
                        : Icons.skip_next_rounded,
                    label: timerState.isFocusPhase ? 'Hoàn tất' : 'Qua pha',
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    onTap: onSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: onDiscard,
                child: Text(
                  timerState.isFocusPhase
                      ? 'Bỏ qua phiên này'
                      : 'Kết thúc nghỉ',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PomodoroCompletionView extends StatelessWidget {
  const _PomodoroCompletionView({
    required this.timerState,
    required this.settings,
    required this.sessions,
    required this.onContinue,
    required this.onEnd,
  });

  final PomodoroTimerState timerState;
  final UserSettingsModel? settings;
  final List<PomodoroSessionModel> sessions;
  final VoidCallback onContinue;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final int focusMinutes = settings?.focusDuration ?? 25;
    final int breakMinutes = timerState.totalSeconds ~/ 60;
    final int streakDays = _calculateCurrentStreak(sessions);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0D1422),
            Color(0xFF0B101A),
            Color(0xFF080C14),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF132238),
                  border: Border.all(color: const Color(0xFF1F3655), width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: Color(0xFF60A5FA),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Hoàn thành!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bạn đã hoàn thành 1 phiên học tập',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 34),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _DarkMetricCard(
                      value: '$focusMinutes',
                      label: 'phút học',
                      valueColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DarkMetricCard(
                      value: '$breakMinutes',
                      label: 'phút nghỉ',
                      valueColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151E2D),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF253043)),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F2937),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '🔥',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Chuỗi hiện tại: $streakDays ngày',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              StudyFlowGradientButton(
                label: 'Tiếp tục phiên tiếp theo',
                onTap: onContinue,
                height: 58,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    Color(0xFF60A5FA),
                    Color(0xFF2563EB),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              StudyFlowOutlineButton(
                label: 'Kết thúc',
                onTap: onEnd,
                height: 56,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PomodoroHistoryView extends StatelessWidget {
  const _PomodoroHistoryView({
    required this.sessions,
    required this.onBack,
  });

  final List<PomodoroSessionModel> sessions;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final int totalMinutes = sessions.fold<int>(
      0,
      (int total, PomodoroSessionModel session) => total + session.duration,
    );
    final int streakDays = _calculateCurrentStreak(sessions);
    final Map<String, List<PomodoroSessionModel>> grouped =
        _groupSessions(sessions);

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF0F172A),
                  Color(0xFF1E3A8A),
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        StudyFlowCircleIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          foregroundColor: Colors.white,
                          onTap: onBack,
                        ),
                        const Expanded(
                          child: Text(
                            'Lịch sử học tập',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _HeroSummaryCard(
                            value: _formatHeroMinutes(totalMinutes),
                            label: 'Tổng thời gian',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HeroSummaryCard(
                            value: '${sessions.length}',
                            label: 'Phiên học',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HeroSummaryCard(
                            value: '🔥 $streakDays',
                            label: 'Ngày liên tiếp',
                            valueColor: const Color(0xFFFBBF24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: sessions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.timer_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có lịch sử học tập',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Hoàn thành một phiên Pomodoro để xem thống kê tại đây.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                    children: grouped.entries.map(
                        (MapEntry<String, List<PomodoroSessionModel>> entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...entry.value.map((PomodoroSessionModel session) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _HistorySessionTile(session: session),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PomodoroRing extends StatelessWidget {
  const _PomodoroRing({
    required this.size,
    required this.progress,
    required this.colors,
    required this.child,
    required this.backgroundColor,
  });

  final double size;
  final double progress;
  final List<Color> colors;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 16,
            color: backgroundColor,
            backgroundColor: backgroundColor,
          ),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ).createShader(bounds);
            },
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 16,
              color: Colors.white,
              backgroundColor: Colors.transparent,
            ),
          ),
          Center(
            child: Container(
              width: size - 54,
              height: size - 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.12),
              ),
              child: Center(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkMetricCard extends StatelessWidget {
  const _DarkMetricCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostActionButton extends StatelessWidget {
  const _GhostActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: const Color(0xFFCBD5E1), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectChipGrid extends StatelessWidget {
  const _SubjectChipGrid({
    required this.subjects,
    required this.selectedSubjectId,
    required this.onSelectSubject,
  });

  final List<SubjectModel> subjects;
  final int? selectedSubjectId;
  final ValueChanged<int?> onSelectSubject;

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có môn học để gắn vào phiên focus',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: subjects.map((SubjectModel subject) {
        final bool selected = selectedSubjectId == subject.id;
        return InkWell(
          onTap: () => onSelectSubject(subject.id),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0xFF172B43) : const Color(0xFF0F1C2E),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF1E293B),
              ),
            ),
            child: Text(
              subject.name,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFBFDBFE)
                    : const Color(0xFFCBD5E1),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RoundTimerAction extends StatelessWidget {
  const _RoundTimerAction({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
    this.foregroundColor = Colors.white,
    this.size = 70,
    this.iconSize = 28,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? <BoxShadow>[
                        BoxShadow(
                          color: backgroundColor.withValues(alpha: 0.32),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: foregroundColor, size: iconSize),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.value,
    required this.label,
    this.valueColor = Colors.white,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySessionTile extends StatelessWidget {
  const _HistorySessionTile({required this.session});

  final PomodoroSessionModel session;

  @override
  Widget build(BuildContext context) {
    final DateTime value = session.completedAt ?? session.sessionDate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: StudyFlowPalette.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  session.subjectName ?? 'Tự học',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.duration} phút • ${_formatTime(value)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_rounded,
            color: Color(0xFF22C55E),
            size: 20,
          ),
        ],
      ),
    );
  }
}

String? _subjectNameFor(int? subjectId, List<SubjectModel> subjects) {
  if (subjectId == null) {
    return null;
  }
  for (final SubjectModel subject in subjects) {
    if (subject.id == subjectId) {
      return subject.name;
    }
  }
  return null;
}

String _breakTitle(PomodoroPhase phase) {
  switch (phase) {
    case PomodoroPhase.focus:
      return 'Đang tập trung';
    case PomodoroPhase.shortBreak:
      return 'Đang nghỉ ngắn';
    case PomodoroPhase.longBreak:
      return 'Đang nghỉ dài';
  }
}

int _completedInCycle(PomodoroTimerState state) {
  return state.completedFocusSessions % 4;
}

int _sessionNumber(PomodoroTimerState state) {
  final int mod = state.completedFocusSessions % 4;
  if (state.isFocusPhase) {
    return mod + 1;
  }
  return mod == 0 ? 4 : mod;
}

String _formatMinutesStat(int minutes) {
  final int hours = minutes ~/ 60;
  final int remainingMinutes = minutes % 60;
  if (hours <= 0) {
    return '${remainingMinutes}m';
  }
  if (remainingMinutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${remainingMinutes}m';
}

String _formatHeroMinutes(int minutes) {
  final int hours = minutes ~/ 60;
  final int remainingMinutes = minutes % 60;
  if (hours <= 0) {
    return '$remainingMinutes m';
  }
  if (remainingMinutes == 0) {
    return '$hours h';
  }
  return '$hours h $remainingMinutes m';
}

String _formatTime(DateTime value) {
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

int _calculateCurrentStreak(List<PomodoroSessionModel> sessions) {
  if (sessions.isEmpty) {
    return 0;
  }

  final Set<DateTime> activeDays = sessions.map((PomodoroSessionModel session) {
    final DateTime value = session.completedAt ?? session.sessionDate;
    return DateTime(value.year, value.month, value.day);
  }).toSet();

  final List<DateTime> orderedDays = activeDays.toList()
    ..sort((DateTime a, DateTime b) => b.compareTo(a));
  DateTime cursor = orderedDays.first;
  int streak = 1;

  while (true) {
    final DateTime previous = cursor.subtract(const Duration(days: 1));
    if (!activeDays.contains(previous)) {
      break;
    }
    streak += 1;
    cursor = previous;
  }

  return streak;
}

Map<String, List<PomodoroSessionModel>> _groupSessions(
  List<PomodoroSessionModel> sessions,
) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  final Map<String, List<PomodoroSessionModel>> grouped =
      <String, List<PomodoroSessionModel>>{};

  for (final PomodoroSessionModel session in sessions) {
    final DateTime value = session.completedAt ?? session.sessionDate;
    final DateTime normalized = DateTime(value.year, value.month, value.day);
    final String key;
    if (normalized == today) {
      key = 'Hôm nay';
    } else if (normalized == yesterday) {
      key = 'Hôm qua';
    } else {
      final String day = normalized.day.toString().padLeft(2, '0');
      final String month = normalized.month.toString().padLeft(2, '0');
      key = '$day/$month/${normalized.year}';
    }
    grouped.putIfAbsent(key, () => <PomodoroSessionModel>[]).add(session);
  }

  return grouped;
}
