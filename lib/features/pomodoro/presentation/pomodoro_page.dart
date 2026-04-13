import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/state/app_refresh_notifier.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../profile/data/user_settings_repository.dart';
import '../../subjects/data/subject_model.dart';
import '../../subjects/data/subject_repository.dart';
import '../data/pomodoro_repository.dart';
import 'pomodoro_controller.dart';
import 'pomodoro_timer_state.dart';
import 'widgets/pomodoro_history_list.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  late final PomodoroController _controller;
  late final SubjectRepository _subjectRepository;
  late Future<List<SubjectModel>> _subjectsFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final DatabaseService databaseService = context.read<DatabaseService>();
    _subjectRepository = SubjectRepository(databaseService);
    _controller = PomodoroController(
      PomodoroRepository(databaseService),
      context.read<UserSettingsRepository>(),
      context.read<AppRefreshNotifier>(),
    );
    _subjectsFuture = _subjectRepository.getSubjects();
    _controller.initialize();
    _initialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          return FutureBuilder<List<SubjectModel>>(
            future: _subjectsFuture,
            builder: (
              BuildContext context,
              AsyncSnapshot<List<SubjectModel>> snapshot,
            ) {
              if (snapshot.connectionState != ConnectionState.done ||
                  _controller.isLoading) {
                return const AppLoadingState(message: 'Preparing pomodoro...');
              }
              if (snapshot.hasError) {
                return AppErrorState(
                  title: 'Unable to load pomodoro',
                  message: 'Try again after your subjects finish loading.',
                  onAction: () {
                    setState(() {
                      _subjectsFuture = _subjectRepository.getSubjects();
                    });
                    _controller.initialize();
                  },
                );
              }

              final List<SubjectModel> subjects =
                  snapshot.data ?? <SubjectModel>[];
              final PomodoroTimerState timerState = _controller.state;
              final String primaryActionLabel = timerState.isRunning
                  ? 'Pause'
                  : timerState.canResume
                      ? 'Resume'
                      : 'Start';
              final String phaseActionLabel =
                  timerState.isFocusPhase ? 'Complete' : 'Skip break';
              final VoidCallback? phaseAction = timerState.isFocusPhase
                  ? (timerState.hasStartedCurrentPhase
                      ? _controller.completeCurrentFocusSession
                      : null)
                  : _controller.skipCurrentBreak;
              return SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            'Pomodoro',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    StudyFlowSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            timerState.phaseLabel,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${timerState.completedFocusSessions} focus sessions completed in this cycle.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: SizedBox(
                              width: 220,
                              height: 220,
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  CircularProgressIndicator(
                                    value: timerState.progress,
                                    strokeWidth: 12,
                                    color: StudyFlowPalette.blue,
                                    backgroundColor:
                                        StudyFlowPalette.surfaceSoft,
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          _controller.formatRemainingTime(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          timerState.phaseLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<int?>(
                            initialValue: timerState.selectedSubjectId,
                            decoration: const InputDecoration(
                                labelText: 'Focus subject'),
                            items: <DropdownMenuItem<int?>>[
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('General study'),
                              ),
                              ...subjects.map(
                                (SubjectModel subject) =>
                                    DropdownMenuItem<int?>(
                                  value: subject.id,
                                  child: Text(subject.name),
                                ),
                              ),
                            ],
                            onChanged: _controller.selectSubject,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: StudyFlowGradientButton(
                                  label: primaryActionLabel,
                                  onTap: _controller.handlePrimaryAction,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StudyFlowOutlineButton(
                                  label: 'Reset',
                                  onTap: _controller.resetCurrentPhase,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StudyFlowOutlineButton(
                                  label: phaseActionLabel,
                                  onTap: phaseAction,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Recent history',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    PomodoroHistoryList(sessions: _controller.history),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
