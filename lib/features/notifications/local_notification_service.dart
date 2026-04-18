import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings();
      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open StudyFlow');

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _initialized = true;
    } catch (error) {
      debugPrint('Notification initialization failed: $error');
    }
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      id,
      title,
      body,
      _notificationDetails,
    );
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    await init();
    await _plugin.cancel(id);
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

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          'studyflow_reminders',
          'StudyFlow reminders',
          channelDescription: 'Local StudyFlow reminders and alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      );
}
