import '../../../core/utils/database_value_utils.dart';
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

  bool get isEnabled => isRead;

  String get scheduleLabel => scheduledAt == null
      ? 'Send now'
      : DateTimeUtils.formatDateTime(scheduledAt!);

  String get repeatLabel {
    switch (type.toLowerCase()) {
      case 'daily':
      case 'hàng ngày':
        return 'Hàng ngày';
      case 'weekly':
      case 'hàng tuần':
        return 'Hàng tuần';
      case 'deadline':
      case 'general':
      case 'none':
      case 'không lặp':
        return 'Không lặp';
      default:
        return type;
    }
  }

  NotificationItemModel copyWith({
    int? id,
    String? type,
    String? title,
    String? message,
    DateTime? scheduledAt,
    bool? clearScheduledAt,
    bool? isRead,
    int? relatedId,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledAt: clearScheduledAt == true
          ? null
          : (scheduledAt ?? this.scheduledAt),
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
    );
  }

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
      id: DatabaseValueUtils.asNullableInt(map['id']),
      type: map['type'] as String? ?? 'general',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      scheduledAt: map['scheduled_at'] == null
          ? null
          : DateTimeUtils.fromDbDateTime(map['scheduled_at'] as String),
      isRead: DatabaseValueUtils.asBool(map['is_read']),
      relatedId: DatabaseValueUtils.asNullableInt(map['related_id']),
    );
  }
}
