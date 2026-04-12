import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_service.dart';
import 'notification_item_model.dart';

class NotificationRepository {
  NotificationRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<NotificationItemModel>> getNotifications() async {
    final Database database = await _databaseService.database;
    final List<Map<String, Object?>> result = await database.query(
      'notifications',
      orderBy: 'scheduled_at DESC, id DESC',
    );
    return result.map(NotificationItemModel.fromMap).toList();
  }

  Future<NotificationItemModel> saveNotification(NotificationItemModel item) async {
    final Database database = await _databaseService.database;
    if (item.id == null) {
      final int id = await database.insert('notifications', item.toMap()..remove('id'));
      return NotificationItemModel(
        id: id,
        type: item.type,
        title: item.title,
        message: item.message,
        scheduledAt: item.scheduledAt,
        isRead: item.isRead,
        relatedId: item.relatedId,
      );
    }

    await database.update(
      'notifications',
      item.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[item.id],
    );
    return item;
  }

  Future<void> markRead(int id, bool isRead) async {
    final Database database = await _databaseService.database;
    await database.update(
      'notifications',
      <String, Object?>{'is_read': isRead ? 1 : 0},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteNotification(int id) async {
    final Database database = await _databaseService.database;
    await database.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
