import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/database_service.dart';
import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_loading_state.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../../auth/application/app_session_controller.dart';
import '../data/notification_item_model.dart';
import '../data/notification_repository.dart';
import '../local_notification_service.dart';
import 'reminder_settings_page.dart';
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

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ReminderSettingsPage(),
      ),
    );
    await _refresh();
  }

  Future<void> _openForm([NotificationItemModel? initialValue]) async {
    final NotificationFormResult? result =
        await Navigator.of(context).push<NotificationFormResult>(
      MaterialPageRoute<NotificationFormResult>(
        builder: (BuildContext context) => NotificationFormSheet(
          initialValue: initialValue,
        ),
      ),
    );
    if (result == null) {
      return;
    }

    if (result.deleteRequested) {
      if (initialValue != null) {
        await _deleteNotification(initialValue);
      }
      return;
    }

    final NotificationItemModel? draft = result.item;
    if (draft == null) {
      return;
    }

    final NotificationItemModel saved = await _repository.saveNotification(draft);
    await _applyScheduling(saved, showDisabledMessage: true);
    await _refresh();
  }

  Future<void> _applyScheduling(
    NotificationItemModel item, {
    bool showDisabledMessage = false,
  }) async {
    final AppSessionController sessionController =
        context.read<AppSessionController>();
    final bool notificationsEnabled =
        sessionController.settings?.notificationsEnabled ?? true;
    final int? id = item.id;
    if (id == null) {
      return;
    }

    await _service.cancel(id);
    if (!item.isEnabled) {
      return;
    }

    if (!notificationsEnabled) {
      if (showDisabledMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nhắc nhở đã được lưu. Bật thông báo trong Cài đặt nhắc nhở để lên lịch.',
            ),
          ),
        );
      }
      return;
    }

    if (item.scheduledAt != null && item.scheduledAt!.isAfter(DateTime.now())) {
      await _service.schedule(
        id: id,
        title: item.title,
        body: item.message,
        scheduledAt: item.scheduledAt!,
      );
      return;
    }

    await _service.showNow(
      id: id,
      title: item.title,
      body: item.message,
    );
  }

  Future<void> _toggleEnabled(NotificationItemModel item) async {
    final int? id = item.id;
    if (id == null) {
      return;
    }
    final bool nextValue = !item.isEnabled;
    await _repository.markRead(id, nextValue);
    await _applyScheduling(item.copyWith(isRead: nextValue));
    await _refresh();
  }

  Future<void> _deleteNotification(NotificationItemModel item) async {
    final int? id = item.id;
    if (id == null) {
      return;
    }

    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Xóa nhắc nhở?',
      message: '"${item.title}" sẽ bị xóa khỏi danh sách nhắc nhở.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    await _repository.deleteNotification(id);
    await _service.cancel(id);
    await _refresh();
  }

  String _relativeDateLabel(DateTime? scheduledAt) {
    if (scheduledAt == null) {
      return 'Bây giờ';
    }
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target =
        DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final int diff = target.difference(today).inDays;
    if (diff == 0) {
      return 'Hôm nay';
    }
    if (diff == 1) {
      return 'Ngày mai';
    }
    final String day = scheduledAt.day.toString().padLeft(2, '0');
    final String month = scheduledAt.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _timeLabel(DateTime? scheduledAt) {
    if (scheduledAt == null) {
      return '--:--';
    }
    final String hour = scheduledAt.hour.toString().padLeft(2, '0');
    final String minute = scheduledAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _summaryLabel(NotificationItemModel item) {
    if (item.scheduledAt == null) {
      return 'Bây giờ · ${item.repeatLabel}';
    }
    return '${_relativeDateLabel(item.scheduledAt)} · ${_timeLabel(item.scheduledAt)} · ${item.repeatLabel}';
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
            return const AppLoadingState(message: 'Đang tải nhắc nhở...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Không thể tải nhắc nhở',
              message: 'Hãy thử làm mới danh sách nhắc nhở.',
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
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Nhắc nhở',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: const Color(0xFF0F172A),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      StudyFlowCircleIconButton(
                        icon: Icons.settings_outlined,
                        size: 40,
                        onTap: _openSettings,
                      ),
                      const SizedBox(width: 10),
                      StudyFlowCircleIconButton(
                        icon: Icons.add_rounded,
                        backgroundColor: StudyFlowPalette.blue,
                        foregroundColor: Colors.white,
                        size: 40,
                        onTap: () => _openForm(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: notificationsEnabled
                            ? const Color(0xFFEFFCF6)
                            : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notificationsEnabled
                            ? 'Thông báo đang bật'
                            : 'Thông báo đang tắt trong cài đặt',
                        style: TextStyle(
                          color: notificationsEnabled
                              ? const Color(0xFF059669)
                              : const Color(0xFFEA580C),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      children: items.isEmpty
                          ? <Widget>[
                              const SizedBox(height: 96),
                              _ReminderEmptyState(
                                onAdd: () => _openForm(),
                              ),
                            ]
                          : items.map((NotificationItemModel item) {
                              final bool enabled = item.isEnabled;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => _openForm(item),
                                  borderRadius: BorderRadius.circular(22),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: StudyFlowPalette.border),
                                      boxShadow: StudyFlowPalette.cardShadow,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                item.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: enabled
                                                          ? const Color(0xFF0F172A)
                                                          : const Color(0xFF94A3B8),
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _summaryLabel(item),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: const Color(0xFF64748B),
                                                      fontSize: 12,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ReminderToggle(
                                          value: enabled,
                                          onChanged: (_) => _toggleEnabled(item),
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

class _ReminderEmptyState extends StatelessWidget {
  const _ReminderEmptyState({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: StudyFlowPalette.surfaceSoft,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF94A3B8),
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Chưa có nhắc nhở',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tạo nhắc nhở để không bỏ lỡ các việc quan trọng.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 24),
        StudyFlowGradientButton(
          label: 'Thêm nhắc nhở',
          onTap: onAdd,
          height: 52,
        ),
      ],
    );
  }
}
