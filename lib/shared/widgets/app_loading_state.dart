import 'package:flutter/material.dart';

import '../../core/theme/studyflow_palette.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.message = 'Loading...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: StudyFlowPalette.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: StudyFlowPalette.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
