import 'package:flutter/material.dart';

import '../../core/theme/studyflow_palette.dart';

class AppConfirmDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: StudyFlowPalette.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StudyFlowPalette.radiusMd)),
          title: Text(title, style: const TextStyle(color: StudyFlowPalette.textPrimary, fontWeight: FontWeight.w700)),
          content: Text(message, style: const TextStyle(color: StudyFlowPalette.textSecondary)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel, style: const TextStyle(color: StudyFlowPalette.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: destructive ? StudyFlowPalette.red : StudyFlowPalette.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StudyFlowPalette.radiusSm)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
