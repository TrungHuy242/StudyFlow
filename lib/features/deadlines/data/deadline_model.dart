import 'package:flutter/material.dart';

import '../../../core/utils/date_time_utils.dart';

class DeadlineModel {
  const DeadlineModel({
    this.id,
    this.subjectId,
    this.subjectName,
    this.subjectColor,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.dueTime,
    required this.priority,
    required this.status,
    required this.progress,
  });

  final int? id;
  final int? subjectId;
  final String? subjectName;
  final String? subjectColor;
  final String title;
  final String description;
  final DateTime dueDate;
  final String? dueTime;
  final String priority;
  final String status;
  final int progress;

  DateTime get dueAt => DateTimeUtils.mergeDateAndTime(dueDate, dueTime);

  bool get isDone => status == 'Done';

  bool get isOverdue => !isDone && dueAt.isBefore(DateTime.now());

  Color get displayColor {
    final String colorHex = subjectColor ?? '#2563EB';
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }

  String get dueLabel {
    final String dateLabel = DateTimeUtils.formatDate(dueDate);
    if (dueTime == null || dueTime!.isEmpty) {
      return dateLabel;
    }
    return '$dateLabel at $dueTime';
  }

  DeadlineModel copyWith({
    int? id,
    int? subjectId,
    String? subjectName,
    String? subjectColor,
    String? title,
    String? description,
    DateTime? dueDate,
    String? dueTime,
    String? priority,
    String? status,
    int? progress,
  }) {
    return DeadlineModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectColor: subjectColor ?? this.subjectColor,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'description': description,
      'due_date': DateTimeUtils.toDbDate(dueDate),
      'due_time': dueTime,
      'priority': priority,
      'status': status,
      'progress': progress,
    };
  }

  factory DeadlineModel.fromMap(Map<String, Object?> map) {
    return DeadlineModel(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int?,
      subjectName: map['subject_name'] as String?,
      subjectColor: map['subject_color'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dueDate: DateTimeUtils.fromDbDate(map['due_date'] as String),
      dueTime: map['due_time'] as String?,
      priority: map['priority'] as String? ?? 'Medium',
      status: map['status'] as String? ?? 'Planned',
      progress: map['progress'] as int? ?? 0,
    );
  }
}
