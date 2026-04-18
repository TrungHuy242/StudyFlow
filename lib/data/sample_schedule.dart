import 'package:flutter/material.dart';

import '../models/schedule_item.dart';

List<ScheduleItem> createSampleSchedule() {
  return const <ScheduleItem>[
    ScheduleItem(
      id: 'ux-ui-design',
      title: 'UX/UI Design',
      weekday: DateTime.monday,
      start: TimeOfDay(hour: 7, minute: 0),
      end: TimeOfDay(hour: 9, minute: 30),
      room: 'A301',
      instructor: 'Th.S Nguyễn Văn A',
      mode: ClassMode.theory,
      color: Color(0xFF7C5CFF),
    ),
    ScheduleItem(
      id: 'web-development',
      title: 'Web Development',
      weekday: DateTime.tuesday,
      start: TimeOfDay(hour: 9, minute: 45),
      end: TimeOfDay(hour: 12, minute: 15),
      room: 'B202',
      instructor: 'Th.S Trần Minh B',
      mode: ClassMode.theory,
      color: Color(0xFF21C26B),
    ),
    ScheduleItem(
      id: 'database-systems',
      title: 'Database Systems',
      weekday: DateTime.wednesday,
      start: TimeOfDay(hour: 13, minute: 0),
      end: TimeOfDay(hour: 15, minute: 30),
      room: 'C105',
      instructor: 'Th.S Lê Thu C',
      mode: ClassMode.practice,
      color: Color(0xFFFFB020),
    ),
    ScheduleItem(
      id: 'english-for-it',
      title: 'English for IT',
      weekday: DateTime.thursday,
      start: TimeOfDay(hour: 7, minute: 0),
      end: TimeOfDay(hour: 9, minute: 0),
      room: 'D401',
      instructor: 'Ms. Anna Nguyen',
      mode: ClassMode.theory,
      color: Color(0xFFFF6B6B),
    ),
  ];
}
