import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/state/app_refresh_notifier.dart';
import '../../profile/data/user_settings_model.dart';
import '../../profile/data/user_settings_repository.dart';
import '../data/pomodoro_repository.dart';
import '../data/pomodoro_session_model.dart';
import 'pomodoro_timer_state.dart';

class PomodoroController extends ChangeNotifier {
  PomodoroController(
    this._repository,
    this._settingsRepository,
    this._refreshNotifier,
  );

  final PomodoroRepository _repository;
  final UserSettingsRepository _settingsRepository;
  final AppRefreshNotifier _refreshNotifier;

  Timer? _ticker;
  UserSettingsModel? _settings;
  bool _isLoading = true;
  List<PomodoroSessionModel> _history = <PomodoroSessionModel>[];
  PomodoroTimerState _state = const PomodoroTimerState(
    phase: PomodoroPhase.focus,
    remainingSeconds: 1500,
    totalSeconds: 1500,
    isRunning: false,
    completedFocusSessions: 0,
    selectedSubjectId: null,
  );

  bool get isLoading => _isLoading;
  PomodoroTimerState get state => _state;
  List<PomodoroSessionModel> get history => _history;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _settings = await _settingsRepository.getSettings();
    _history = await _repository.getSessions();
    _state = _createStateForPhase(
      phase: PomodoroPhase.focus,
      completedFocusSessions: _state.completedFocusSessions,
      selectedSubjectId: _state.selectedSubjectId,
    );

    _isLoading = false;
    notifyListeners();
  }

  void selectSubject(int? subjectId) {
    _state = _state.copyWith(selectedSubjectId: subjectId);
    notifyListeners();
  }

  void handlePrimaryAction() {
    if (_state.isRunning) {
      pauseTimer();
      return;
    }

    startOrResumeTimer();
  }

  void startOrResumeTimer() {
    _ticker?.cancel();
    _state = _state.copyWith(isRunning: true);
    notifyListeners();
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if (_state.remainingSeconds <= 1) {
        timer.cancel();
        await _finishCurrentPhase();
        return;
      }
      _state = _state.copyWith(remainingSeconds: _state.remainingSeconds - 1);
      notifyListeners();
    });
  }

  void pauseTimer() {
    _ticker?.cancel();
    _state = _state.copyWith(isRunning: false);
    notifyListeners();
  }

  void resetCurrentPhase() {
    _ticker?.cancel();
    _state = _createStateForPhase(
      phase: _state.phase,
      completedFocusSessions: _state.completedFocusSessions,
      selectedSubjectId: _state.selectedSubjectId,
    );
    notifyListeners();
  }

  Future<void> completeCurrentFocusSession() async {
    if (!_state.isFocusPhase || !_state.hasStartedCurrentPhase) {
      return;
    }

    _ticker?.cancel();
    await _finishCurrentPhase(
      completedAt: DateTime.now(),
      durationMinutes: _elapsedFocusMinutes,
    );
  }

  Future<void> skipCurrentBreak() async {
    if (!_state.isBreakPhase) {
      return;
    }

    _ticker?.cancel();
    _state = _createStateForPhase(
      phase: PomodoroPhase.focus,
      completedFocusSessions: _state.completedFocusSessions,
      selectedSubjectId: _state.selectedSubjectId,
    );
    notifyListeners();
  }

  int get _elapsedFocusMinutes {
    final int elapsedSeconds = (_state.totalSeconds - _state.remainingSeconds)
        .clamp(0, _state.totalSeconds);
    if (elapsedSeconds <= 0) {
      return 0;
    }
    return (elapsedSeconds / 60).ceil();
  }

  Future<void> _finishCurrentPhase({
    DateTime? completedAt,
    int? durationMinutes,
  }) async {
    if (_state.isFocusPhase) {
      final int loggedMinutes = durationMinutes ??
          (_settings?.focusDuration ?? _state.totalSeconds ~/ 60);
      final DateTime finishedAt = completedAt ?? DateTime.now();
      await _repository.saveSession(
        PomodoroSessionModel(
          subjectId: _state.selectedSubjectId,
          sessionDate: DateTime(
            finishedAt.year,
            finishedAt.month,
            finishedAt.day,
          ),
          duration: loggedMinutes,
          type: 'Focus',
          completedAt: finishedAt,
        ),
      );
      _history = await _repository.getSessions();
      _refreshNotifier.markDirty();
    }

    final int completedFocusSessions = _state.isFocusPhase
        ? _state.completedFocusSessions + 1
        : _state.completedFocusSessions;
    final PomodoroPhase nextPhase;
    if (_state.isFocusPhase) {
      nextPhase = completedFocusSessions % 4 == 0
          ? PomodoroPhase.longBreak
          : PomodoroPhase.shortBreak;
    } else {
      nextPhase = PomodoroPhase.focus;
    }

    _state = _createStateForPhase(
      phase: nextPhase,
      completedFocusSessions: completedFocusSessions,
      selectedSubjectId: _state.selectedSubjectId,
    );
    notifyListeners();
  }

  PomodoroTimerState _createStateForPhase({
    required PomodoroPhase phase,
    required int completedFocusSessions,
    required int? selectedSubjectId,
  }) {
    final int minutes = switch (phase) {
      PomodoroPhase.focus => _settings?.focusDuration ?? 25,
      PomodoroPhase.shortBreak => _settings?.shortBreakDuration ?? 5,
      PomodoroPhase.longBreak => _settings?.longBreakDuration ?? 15,
    };

    return PomodoroTimerState(
      phase: phase,
      remainingSeconds: minutes * 60,
      totalSeconds: minutes * 60,
      isRunning: false,
      completedFocusSessions: completedFocusSessions,
      selectedSubjectId: selectedSubjectId,
    );
  }

  String formatRemainingTime() {
    final int minutes = _state.remainingSeconds ~/ 60;
    final int seconds = _state.remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
