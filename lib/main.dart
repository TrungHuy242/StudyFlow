import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/database_service.dart';
import 'core/migration/legacy_sqlite_migration_service.dart';
import 'core/routes/app_router.dart';
import 'core/state/app_refresh_notifier.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/app_session_controller.dart';
import 'features/notifications/notification_sync_service.dart';
import 'features/profile/data/user_settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.instance.init();
  final LegacySqliteMigrationService migrationService =
      LegacySqliteMigrationService(DatabaseService.instance);

  final UserSettingsRepository userSettingsRepository = UserSettingsRepository(
    DatabaseService.instance,
  );
  final AppSessionController sessionController = AppSessionController(
    userSettingsRepository,
    migrationService,
  );
  final AppRefreshNotifier appRefreshNotifier = AppRefreshNotifier();

  await sessionController.hydrate();

  final NotificationSyncService notificationSyncService =
      NotificationSyncService(databaseService: DatabaseService.instance);

  final settings = sessionController.settings;
  if (settings != null &&
      settings.isAuthenticated &&
      settings.notificationsEnabled) {
    try {
      await notificationSyncService.syncForSettings(settings);
    } catch (e) {
      // Notification resync is best-effort for local reminders.
    }
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

class StudyFlowBootstrap extends StatefulWidget {
  const StudyFlowBootstrap({
    super.key,
    required this.appRefreshNotifier,
    required this.notificationSyncService,
    required this.userSettingsRepository,
    required this.sessionController,
  });

  final AppRefreshNotifier appRefreshNotifier;
  final NotificationSyncService notificationSyncService;
  final UserSettingsRepository userSettingsRepository;
  final AppSessionController sessionController;

  @override
  State<StudyFlowBootstrap> createState() => _StudyFlowBootstrapState();
}

class _StudyFlowBootstrapState extends State<StudyFlowBootstrap> {
  late AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(widget.sessionController);
  }

  @override
  void didUpdateWidget(covariant StudyFlowBootstrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sessionController, widget.sessionController)) {
      _appRouter = AppRouter(widget.sessionController);
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _appRouter = AppRouter(widget.sessionController);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: DatabaseService.instance),
        Provider<UserSettingsRepository>.value(
          value: widget.userSettingsRepository,
        ),
        Provider<NotificationSyncService>.value(
          value: widget.notificationSyncService,
        ),
        ChangeNotifierProvider<AppRefreshNotifier>.value(
          value: widget.appRefreshNotifier,
        ),
        ChangeNotifierProvider<AppSessionController>.value(
          value: widget.sessionController,
        ),
      ],
      child: Consumer<AppSessionController>(
        builder: (BuildContext context, AppSessionController session, _) {
          return MaterialApp.router(
            title: 'StudyFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: session.settings?.darkMode ?? false
                ? ThemeMode.dark
                : ThemeMode.light,
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
