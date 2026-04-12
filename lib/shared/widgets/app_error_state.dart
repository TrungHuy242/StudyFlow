import 'package:flutter/material.dart';

import '../../core/theme/studyflow_palette.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = 'Retry',
    this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: StudyFlowPalette.surface,
          borderRadius: BorderRadius.circular(StudyFlowPalette.radiusMd),
          border: Border.all(color: StudyFlowPalette.border),
          boxShadow: StudyFlowPalette.cardShadow,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: StudyFlowPalette.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline_rounded, color: StudyFlowPalette.red, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: StudyFlowPalette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: StudyFlowPalette.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...<Widget>[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: StudyFlowPalette.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: StudyFlowPalette.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
