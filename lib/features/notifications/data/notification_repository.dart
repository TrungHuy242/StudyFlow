import '../../../core/database/database_service.dart';
import '../../../core/data/user_scope.dart';
import 'notification_item_model.dart';

class NotificationRepository {
  NotificationRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<NotificationItemModel>> getNotifications() async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final List<dynamic> result = await _databaseService.client
        .from('notifications')
        .select('id, type, title, message, scheduled_at, is_read, related_id')
        .gte('id', minId)
        .lt('id', maxId)
        .order('scheduled_at', ascending: false)
        .order('id', ascending: false);
    return result
        .map(
          (dynamic item) => NotificationItemModel.fromMap(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<NotificationItemModel> saveNotification(NotificationItemModel item) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    final Map<String, Object?> payload = <String, Object?>{
      'type': item.type,
      'title': item.title,
      'message': item.message,
      'scheduled_at': item.scheduledAt?.toUtc().toIso8601String(),
      'is_read': item.isRead,
      'related_id': item.relatedId,
    };

    if (item.id == null) {
      final dynamic inserted = await _databaseService.client
          .from('notifications')
          .insert(<String, Object?>{
            'id': UserScope.generateId(userId),
            ...payload,
          })
          .select('id, type, title, message, scheduled_at, is_read, related_id')
          .single();
      return NotificationItemModel.fromMap(
        Map<String, Object?>.from(inserted as Map),
      );
    }

    await _databaseService.client
        .from('notifications')
        .update(payload)
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', item.id!);
    return item;
  }

  Future<void> markRead(int id, bool isRead) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    await _databaseService.client
        .from('notifications')
        .update(<String, Object?>{'is_read': isRead})
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id);
  }

  Future<void> deleteNotification(int id) async {
    final String userId = _databaseService.requireUserId();
    final int minId = UserScope.baseForUser(userId);
    final int maxId = UserScope.upperBoundForUser(userId);
    await _databaseService.client
        .from('notifications')
        .delete()
        .gte('id', minId)
        .lt('id', maxId)
        .eq('id', id);
  }
}
