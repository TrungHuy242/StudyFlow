import '../../core/database/database_service.dart';
import '../profile/data/user_settings_model.dart';
import 'data/notification_item_model.dart';
import 'data/notification_repository.dart';
import 'local_notification_service.dart';

class NotificationSyncService {
  NotificationSyncService({
    required DatabaseService databaseService,
    LocalNotificationService? localNotificationService,
  })  : _repository = NotificationRepository(databaseService),
        _localNotificationService =
            localNotificationService ?? LocalNotificationService.instance;

  final NotificationRepository _repository;
  final LocalNotificationService _localNotificationService;

  Future<void> syncForSettings(UserSettingsModel settings) async {
    if (!settings.notificationsEnabled) {
      await _localNotificationService.cancelAll();
      return;
    }

    final List<NotificationItemModel> notifications =
        await _repository.getNotifications();
    final DateTime now = DateTime.now();

    for (final NotificationItemModel item in notifications) {
      final int? id = item.id;
      if (id == null) {
        continue;
      }

      if (!item.isEnabled) {
        await _localNotificationService.cancel(id);
        continue;
      }

      if (item.scheduledAt == null || !item.scheduledAt!.isAfter(now)) {
        await _localNotificationService.cancel(id);
        continue;
      }

      await _localNotificationService.schedule(
        id: id,
        title: item.title,
        body: item.message,
        scheduledAt: item.scheduledAt!,
      );
    }
  }
}
