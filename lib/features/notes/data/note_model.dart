import 'package:flutter/material.dart';

import '../../../core/utils/database_value_utils.dart';
import '../../../core/utils/date_time_utils.dart';

class NoteModel {
  const NoteModel({
    this.id,
    this.subjectId,
    this.subjectName,
    required this.title,
    required this.content,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int? subjectId;
  final String? subjectName;
  final String title;
  final String content;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color get displayColor => Color(int.parse(color.replaceFirst('#', '0xFF')));

  String get updatedLabel => DateTimeUtils.formatDateTime(updatedAt);

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'content': content,
      'color': color,
      'created_at': DateTimeUtils.toDbDateTime(createdAt),
      'updated_at': DateTimeUtils.toDbDateTime(updatedAt),
    };
  }

  factory NoteModel.fromMap(Map<String, Object?> map) {
    return NoteModel(
      id: DatabaseValueUtils.asNullableInt(map['id']),
      subjectId: DatabaseValueUtils.asNullableInt(map['subject_id']),
      subjectName: map['subject_name'] as String?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      color: map['color'] as String? ?? '#2563EB',
      createdAt: DateTimeUtils.fromDbDateTime(map['created_at'] as String),
      updatedAt: DateTimeUtils.fromDbDateTime(map['updated_at'] as String),
    );
  }
}
