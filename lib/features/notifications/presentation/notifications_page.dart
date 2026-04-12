import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../auth/application/app_session_controller.dart';
import '../data/notification_item_model.dart';
import '../data/notification_repository.dart';
import '../local_notification_service.dart';
import 'widgets/notification_form_sheet.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationRepository _repository;
  late final LocalNotificationService _service;
  late Future<List<NotificationItemModel>> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _repository = NotificationRepository(context.read<DatabaseService>());
    _service = LocalNotificationService.instance;
    _future = _repository.getNotifications();
    _initialized = true;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repository.getNotifications();
    });
    await _future;
  }

  Future<void> _openForm() async {
    final AppSessionController sessionController =
        context.read<AppSessionController>();
    final NotificationItemModel? draft =
        await showModalBottomSheet<NotificationItemModel>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const NotificationFormSheet(),
    );
    if (draft == null) {
      return;
    }

    final NotificationItemModel saved =
        await _repository.saveNotification(draft);
    final int? id = saved.id;
    if (id != null) {
      final bool notificationsEnabled =
          sessionController.settings?.notificationsEnabled ?? true;
      if (!notificationsEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Reminder saved. Enable notifications in Profile to schedule it.',
              ),
            ),
          );
        }
      } else if (saved.scheduledAt != null &&
          saved.scheduledAt!.isAfter(DateTime.now())) {
        await _service.schedule(
          id: id,
          title: saved.title,
          body: saved.message,
          scheduledAt: saved.scheduledAt!,
        );
      } else {
        await _service.showNow(
          id: id,
          title: saved.title,
          body: saved.message,
        );
      }
    }

    await _refresh();
  }

  Future<void> _toggleRead(NotificationItemModel item) async {
    final int? id = item.id;
    if (id == null) {
      return;
    }
    await _repository.markRead(id, !item.isRead);
    await _refresh();
  }

  Future<void> _deleteNotification(NotificationItemModel item) async {
    final int? id = item.id;
    if (id == null) {
      return;
    }

    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete reminder?',
      message: '"${item.title}" will be removed from your reminder list.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    await _repository.deleteNotification(id);
    await _service.cancel(id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<NotificationItemModel>>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<NotificationItemModel>> snapshot,
        ) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingState(message: 'Loading reminders...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load reminders',
              message: 'Try refreshing the reminder list.',
              onAction: _refresh,
            );
          }

          final List<NotificationItemModel> items =
              snapshot.data ?? <NotificationItemModel>[];
          final bool notificationsEnabled = context
                  .watch<AppSessionController>()
                  .settings
                  ?.notificationsEnabled ??
              true;

          return SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Reminders',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      StudyFlowCircleIconButton(
                        icon: Icons.add_rounded,
                        backgroundColor: StudyFlowPalette.blue,
                        foregroundColor: Colors.white,
                        onTap: _openForm,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: notificationsEnabled
                          ? StudyFlowPalette.green.withValues(alpha: 0.10)
                          : StudyFlowPalette.orange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      notificationsEnabled
                          ? 'Notifications are enabled'
                          : 'Notifications are disabled in Profile',
                      style: TextStyle(
                        color: notificationsEnabled
                            ? StudyFlowPalette.green
                            : StudyFlowPalette.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: items.isEmpty
                          ? <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 48),
                                child: AppEmptyState(
                                  title: 'No reminders yet',
                                  message:
                                      'Create a reminder to keep important tasks visible.',
                                  actionLabel: 'Add reminder',
                                  onAction: _openForm,
                                ),
                              ),
                            ]
                          : items.map((NotificationItemModel item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: InkWell(
                                  onTap: () => _toggleRead(item),
                                  borderRadius: BorderRadius.circular(20),
                                  child: StudyFlowSurfaceCard(
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: item.isRead
                                                ? StudyFlowPalette.surfaceSoft
                                                : StudyFlowPalette.blue
                                                    .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            item.isRead
                                                ? Icons
                                                    .notifications_none_rounded
                                                : Icons
                                                    .notifications_active_rounded,
                                            color: item.isRead
                                                ? StudyFlowPalette.textMuted
                                                : StudyFlowPalette.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                item.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.scheduleLabel} | ${item.type}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (String value) async {
                                            switch (value) {
                                              case 'toggle':
                                                await _toggleRead(item);
                                                break;
                                              case 'delete':
                                                await _deleteNotification(item);
                                                break;
                                            }
                                          },
                                          itemBuilder:
                                              (BuildContext context) =>
                                                  <PopupMenuEntry<String>>[
                                            PopupMenuItem<String>(
                                              value: 'toggle',
                                              child: Text(
                                                item.isRead
                                                    ? 'Mark as unread'
                                                    : 'Mark as read',
                                              ),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
