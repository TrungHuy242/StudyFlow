import '../../../core/utils/date_time_utils.dart';

class StudyPlanModel {
  const StudyPlanModel({
    this.id,
    this.subjectId,
    this.subjectName,
    this.subjectColor,
    required this.title,
    required this.planDate,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.topic,
    required this.status,
  });

  final int? id;
  final int? subjectId;
  final String? subjectName;
  final String? subjectColor;
  final String title;
  final DateTime planDate;
  final String? startTime;
  final String? endTime;
  final int duration;
  final String topic;
  final String status;

  String get dateLabel => DateTimeUtils.formatWeekdayDate(planDate);

  String get timeLabel {
    if (startTime == null || endTime == null) {
      return '$duration min';
    }
    return '$startTime - $endTime';
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'plan_date': DateTimeUtils.toDbDate(planDate),
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'topic': topic,
      'status': status,
    };
  }

  factory StudyPlanModel.fromMap(Map<String, Object?> map) {
    return StudyPlanModel(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int?,
      subjectName: map['subject_name'] as String?,
      subjectColor: map['subject_color'] as String?,
      title: map['title'] as String? ?? '',
      planDate: DateTimeUtils.fromDbDate(map['plan_date'] as String),
      startTime: map['start_time'] as String?,
      endTime: map['end_time'] as String?,
      duration: map['duration'] as int? ?? 60,
      topic: map['topic'] as String? ?? '',
      status: map['status'] as String? ?? 'Planned',
    );
  }
}
