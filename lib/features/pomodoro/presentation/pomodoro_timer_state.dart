enum PomodoroPhase { focus, shortBreak, longBreak }

class PomodoroTimerState {
  const PomodoroTimerState({
    required this.phase,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.completedFocusSessions,
    required this.selectedSubjectId,
  });

  final PomodoroPhase phase;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final int completedFocusSessions;
  final int? selectedSubjectId;

  bool get isFocusPhase => phase == PomodoroPhase.focus;

  bool get isBreakPhase => !isFocusPhase;

  bool get hasStartedCurrentPhase => remainingSeconds < totalSeconds;

  bool get canResume => !isRunning && hasStartedCurrentPhase;

  String get phaseLabel {
    switch (phase) {
      case PomodoroPhase.focus:
        return 'Focus';
      case PomodoroPhase.shortBreak:
        return 'Short break';
      case PomodoroPhase.longBreak:
        return 'Long break';
    }
  }

  double get progress {
    if (totalSeconds == 0) {
      return 0;
    }
    return 1 - (remainingSeconds / totalSeconds);
  }

  PomodoroTimerState copyWith({
    PomodoroPhase? phase,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    int? completedFocusSessions,
    int? selectedSubjectId,
  }) {
    return PomodoroTimerState(
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      completedFocusSessions:
          completedFocusSessions ?? this.completedFocusSessions,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
    );
  }
}
