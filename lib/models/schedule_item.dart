import 'package:flutter/material.dart';

enum ClassMode { theory, practice }

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.title,
    required this.weekday,
    required this.start,
    required this.end,
    required this.room,
    required this.instructor,
    required this.mode,
    required this.color,
    this.attended = false,
    this.reminderEnabled = false,
  });

  final String id;
  final String title;
  final int weekday;
  final TimeOfDay start;
  final TimeOfDay end;
  final String room;
  final String instructor;
  final ClassMode mode;
  final Color color;
  final bool attended;
  final bool reminderEnabled;

  String get modeLabel => mode == ClassMode.theory ? 'Lý thuyết' : 'Thực hành';

  String get weekdayLabel => weekdayName(weekday);

  String get shortTitle {
    if (title == 'Web Development') {
      return 'Web Dev';
    }
    if (title == 'Database Systems') {
      return 'Database';
    }
    if (title == 'UX/UI Design') {
      return 'UX/UI';
    }
    return title.length <= 10 ? title : title.substring(0, 10);
  }

  String timeRange(BuildContext context) {
    return '${formatTimeOfDay(start)} - ${formatTimeOfDay(end)}';
  }

  ScheduleItem copyWith({
    String? id,
    String? title,
    int? weekday,
    TimeOfDay? start,
    TimeOfDay? end,
    String? room,
    String? instructor,
    ClassMode? mode,
    Color? color,
    bool? attended,
    bool? reminderEnabled,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      weekday: weekday ?? this.weekday,
      start: start ?? this.start,
      end: end ?? this.end,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      mode: mode ?? this.mode,
      color: color ?? this.color,
      attended: attended ?? this.attended,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}

String weekdayName(int weekday) {
  const labels = <int, String>{
    DateTime.monday: 'Thứ 2',
    DateTime.tuesday: 'Thứ 3',
    DateTime.wednesday: 'Thứ 4',
    DateTime.thursday: 'Thứ 5',
    DateTime.friday: 'Thứ 6',
    DateTime.saturday: 'Thứ 7',
    DateTime.sunday: 'CN',
  };

  return labels[weekday] ?? 'Thứ 2';
}

String compactWeekdayName(int weekday) {
  const labels = <int, String>{
    DateTime.monday: 'T2',
    DateTime.tuesday: 'T3',
    DateTime.wednesday: 'T4',
    DateTime.thursday: 'T5',
    DateTime.friday: 'T6',
    DateTime.saturday: 'T7',
    DateTime.sunday: 'CN',
  };

  return labels[weekday] ?? 'T2';
}

String formatTimeOfDay(TimeOfDay time) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
}
