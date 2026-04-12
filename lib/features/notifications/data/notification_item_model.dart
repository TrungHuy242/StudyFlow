import '../../../core/utils/date_time_utils.dart';

class NotificationItemModel {
  const NotificationItemModel({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    this.scheduledAt,
    required this.isRead,
    this.relatedId,
  });

  final int? id;
  final String type;
  final String title;
  final String message;
  final DateTime? scheduledAt;
  final bool isRead;
  final int? relatedId;

  String get scheduleLabel => scheduledAt == null
      ? 'Send now'
      : DateTimeUtils.formatDateTime(scheduledAt!);

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'scheduled_at': scheduledAt == null ? null : DateTimeUtils.toDbDateTime(scheduledAt!),
      'is_read': isRead ? 1 : 0,
      'related_id': relatedId,
    };
  }

  factory NotificationItemModel.fromMap(Map<String, Object?> map) {
    return NotificationItemModel(
      id: map['id'] as int?,
      type: map['type'] as String? ?? 'general',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      scheduledAt: map['scheduled_at'] == null
          ? null
          : DateTimeUtils.fromDbDateTime(map['scheduled_at'] as String),
      isRead: (map['is_read'] as int? ?? 0) == 1,
      relatedId: map['related_id'] as int?,
    );
  }
}
