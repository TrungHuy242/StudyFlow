import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service quản lý thông báo cục bộ (local notifications)
class LocalNotificationService {
  // Constructor private để đảm bảo singleton
  LocalNotificationService._();

  /// Instance duy nhất (singleton) để sử dụng trong toàn bộ ứng dụng
  static final LocalNotificationService instance = LocalNotificationService._();

  /// Plugin chính để làm việc với thông báo cục bộ
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Biến cờ để kiểm tra đã khởi tạo hay chưa
  bool _initialized = false;

  /// Khởi tạo service và xin quyền thông báo trên các nền tảng
  Future<void> init() async {
    if (_initialized) {
      // Nếu đã khởi tạo rồi thì không cần làm lại
      return;
    }

    try {
      // Khởi tạo timezone để hỗ trợ schedule chính xác
      tz.initializeTimeZones();

      // Cấu hình cho Android
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Cấu hình cho iOS và macOS
      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings();

      // Cấu hình cho Linux
      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open StudyFlow');

      // Tổng hợp cấu hình cho tất cả nền tảng
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      // Khởi tạo plugin với cấu hình
      await _plugin.initialize(settings);

      // Xin quyền thông báo trên Android
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      // Xin quyền thông báo trên iOS
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // Xin quyền thông báo trên macOS
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // Đánh dấu đã khởi tạo
      _initialized = true;
    } catch (error) {
      // In ra lỗi nếu khởi tạo thất bại
      debugPrint('Notification initialization failed: $error');
    }
  }

  /// Hiển thị thông báo ngay lập tức
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(id, title, body, _notificationDetails);
  }

  /// Lên lịch thông báo tại một thời điểm cụ thể
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    await init();
    // Hủy thông báo cũ nếu có cùng id
    await _plugin.cancel(id);
    // Lên lịch thông báo mới
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.UTC),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Hủy một thông báo theo id
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  /// Hủy tất cả thông báo
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Cấu hình chi tiết thông báo cho từng nền tảng
  NotificationDetails get _notificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'studyflow_reminders', // ID của channel
      'StudyFlow reminders', // Tên channel
      channelDescription:
          'Local StudyFlow reminders and alerts', // Mô tả channel
      importance: Importance.max, // Độ ưu tiên cao nhất
      priority: Priority.high, // Hiển thị ưu tiên cao
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
  );
}
