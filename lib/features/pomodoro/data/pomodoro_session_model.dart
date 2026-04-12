import '../../../core/utils/date_time_utils.dart';

class PomodoroSessionModel {
  const PomodoroSessionModel({
    this.id,
    this.subjectId,
    this.subjectName,
    required this.sessionDate,
    required this.duration,
    required this.type,
    this.completedAt,
  });

  final int? id;
  final int? subjectId;
  final String? subjectName;
  final DateTime sessionDate;
  final int duration;
  final String type;
  final DateTime? completedAt;

  String get completedLabel {
    final DateTime value = completedAt ?? sessionDate;
    return DateTimeUtils.formatDateTime(value);
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'subject_id': subjectId,
      'session_date': DateTimeUtils.toDbDate(sessionDate),
      'duration': duration,
      'type': type,
      'completed_at': completedAt == null ? null : DateTimeUtils.toDbDateTime(completedAt!),
    };
  }

  factory PomodoroSessionModel.fromMap(Map<String, Object?> map) {
    return PomodoroSessionModel(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int?,
      subjectName: map['subject_name'] as String?,
      sessionDate: DateTimeUtils.fromDbDate(map['session_date'] as String),
      duration: map['duration'] as int? ?? 0,
      type: map['type'] as String? ?? 'Focus',
      completedAt: map['completed_at'] == null
          ? null
          : DateTimeUtils.fromDbDateTime(map['completed_at'] as String),
    );
  }
}
