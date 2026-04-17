import '../../core/database/database_service.dart';
import '../profile/data/user_settings_model.dart';
import 'data/notification_item_model.dart';
import 'data/notification_repository.dart';
import 'local_notification_service.dart';

/// Service dùng để đồng bộ thông báo giữa cơ sở dữ liệu và hệ thống thông báo cục bộ
class NotificationSyncService {
  NotificationSyncService({
    required DatabaseService databaseService,
    LocalNotificationService? localNotificationService,
  }) : _repository = NotificationRepository(databaseService),
       _localNotificationService =
           localNotificationService ?? LocalNotificationService.instance;

  final NotificationRepository _repository;
  final LocalNotificationService _localNotificationService;

  /// Đồng bộ thông báo dựa trên cài đặt của người dùng
  Future<void> syncForSettings(UserSettingsModel settings) async {
    // Nếu người dùng tắt thông báo → hủy tất cả thông báo cục bộ
    if (!settings.notificationsEnabled) {
      await _localNotificationService.cancelAll();
      return;
    }

    // Lấy danh sách thông báo từ cơ sở dữ liệu
    final List<NotificationItemModel> notifications = await _repository
        .getNotifications();
    final DateTime now = DateTime.now();

    // Duyệt qua từng thông báo để xử lý
    for (final NotificationItemModel item in notifications) {
      final int? id = item.id;
      if (id == null) {
        // Nếu thông báo không có id → bỏ qua
        continue;
      }

      if (!item.isEnabled) {
        // Nếu thông báo bị tắt → hủy thông báo theo id
        await _localNotificationService.cancel(id);
        continue;
      }

      if (item.scheduledAt == null || !item.scheduledAt!.isAfter(now)) {
        // Nếu không có thời gian hoặc thời gian đã qua → hủy thông báo
        await _localNotificationService.cancel(id);
        continue;
      }

      // Nếu hợp lệ → lên lịch thông báo
      await _localNotificationService.schedule(
        id: id,
        title: item.title,
        body: item.message,
        scheduledAt: item.scheduledAt!,
      );
    }
  }
}
