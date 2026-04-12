import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/database_service.dart';
import 'core/routes/app_router.dart';
import 'core/state/app_refresh_notifier.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/app_session_controller.dart';
import 'features/notifications/notification_sync_service.dart';
import 'features/profile/data/user_settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseService.instance.init();
  } catch (e) {
    // Database may fail on web - continue anyway
  }

  final UserSettingsRepository userSettingsRepository = UserSettingsRepository(
    DatabaseService.instance,
  );
  final AppSessionController sessionController = AppSessionController(
    userSettingsRepository,
  );
  final AppRefreshNotifier appRefreshNotifier = AppRefreshNotifier();

  try {
    await sessionController.hydrate();
  } catch (e) {
    // Hydration may fail if database is unavailable - continue anyway
  }

  final NotificationSyncService notificationSyncService =
      NotificationSyncService(databaseService: DatabaseService.instance);

  try {
    final settings = sessionController.settings;
    if (settings != null && settings.notificationsEnabled) {
      await notificationSyncService.syncForSettings(settings);
    }
  } catch (e) {
    // Notification resync is best-effort for local reminders.
  }

  runApp(
    StudyFlowBootstrap(
      appRefreshNotifier: appRefreshNotifier,
      notificationSyncService: notificationSyncService,
      userSettingsRepository: userSettingsRepository,
      sessionController: sessionController,
    ),
  );
}

class StudyFlowBootstrap extends StatelessWidget {
  StudyFlowBootstrap({
    super.key,
    required this.appRefreshNotifier,
    required this.notificationSyncService,
    required this.userSettingsRepository,
    required this.sessionController,
  }) : _appRouter = AppRouter(sessionController);

  final AppRefreshNotifier appRefreshNotifier;
  final NotificationSyncService notificationSyncService;
  final UserSettingsRepository userSettingsRepository;
  final AppSessionController sessionController;
  final AppRouter _appRouter;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: DatabaseService.instance),
        Provider<UserSettingsRepository>.value(value: userSettingsRepository),
        Provider<NotificationSyncService>.value(value: notificationSyncService),
        ChangeNotifierProvider<AppRefreshNotifier>.value(value: appRefreshNotifier),
        ChangeNotifierProvider<AppSessionController>.value(value: sessionController),
      ],
      child: Consumer<AppSessionController>(
        builder: (BuildContext context, AppSessionController session, _) {
          return MaterialApp.router(
            title: 'StudyFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode:
                session.settings?.darkMode ?? false ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
