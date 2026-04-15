import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/database_value_utils.dart';

class ScheduleModel {
  const ScheduleModel({
    this.id,
    required this.subjectId,
    this.subjectName,
    this.subjectColor,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.type,
  });

  final int? id;
  final int subjectId;
  final String? subjectName;
  final String? subjectColor;
  final int weekday;
  final String startTime;
  final String endTime;
  final String room;
  final String type;

  String get weekdayLabel => AppConstants.weekdayLabels[weekday - 1];

  Color get displayColor {
    final String colorHex = subjectColor ?? '#2563EB';
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }

  String get timeRange => '$startTime - $endTime';

  ScheduleModel copyWith({
    int? id,
    int? subjectId,
    String? subjectName,
    String? subjectColor,
    int? weekday,
    String? startTime,
    String? endTime,
    String? room,
    String? type,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectColor: subjectColor ?? this.subjectColor,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      type: type ?? this.type,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'subject_id': subjectId,
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
      'room': room,
      'type': type,
    };
  }

  factory ScheduleModel.fromMap(Map<String, Object?> map) {
    return ScheduleModel(
      id: DatabaseValueUtils.asNullableInt(map['id']),
      subjectId: DatabaseValueUtils.asInt(map['subject_id']),
      subjectName: map['subject_name'] as String?,
      subjectColor: map['subject_color'] as String?,
      weekday: DatabaseValueUtils.asInt(map['weekday'], fallback: 1),
      startTime: DatabaseValueUtils.normalizeTimeString(
        map['start_time'],
        fallback: '08:00',
      ),
      endTime: DatabaseValueUtils.normalizeTimeString(
        map['end_time'],
        fallback: '09:00',
      ),
      room: map['room'] as String? ?? '',
      type: map['type'] as String? ?? 'Lecture',
    );
  }
}
