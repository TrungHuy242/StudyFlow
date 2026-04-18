import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_empty_state.dart';
import '../../data/pomodoro_session_model.dart';

class PomodoroHistoryList extends StatelessWidget {
  const PomodoroHistoryList({
    super.key,
    required this.sessions,
  });

  final List<PomodoroSessionModel> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const AppEmptyState(
        title: 'No focus sessions yet',
        message: 'Complete a pomodoro session to build your local history.',
      );
    }

    return Column(
      children: sessions.take(6).map((PomodoroSessionModel session) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              title: Text('${session.type} | ${session.duration} min'),
              subtitle: Text(session.completedLabel),
              trailing: Text(session.subjectName ?? 'General'),
            ),
          ),
        );
      }).toList(),
    );
  }
}
