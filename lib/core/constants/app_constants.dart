import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'StudyFlow';
  static const String databaseName = 'studyflow.db';

  static const double screenPadding = 20;
  static const double sectionSpacing = 20;
  static const double itemSpacing = 12;
  static const double radius = 18;
  static const double smallRadius = 12;

  static const List<String> weekdayLabels = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> deadlinePriorities = <String>['High', 'Medium', 'Low'];

  static const List<String> progressStatuses = <String>[
    'Planned',
    'In progress',
    'Done',
  ];

  static const List<Color> subjectPalette = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0F766E),
    Color(0xFFEA580C),
    Color(0xFFA21CAF),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
    Color(0xFF65A30D),
  ];
}
