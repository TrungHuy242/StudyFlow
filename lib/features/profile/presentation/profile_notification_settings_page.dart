import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/application/app_session_controller.dart';
import '../../notifications/notification_sync_service.dart';
import '../data/user_settings_model.dart';
import '../data/user_settings_repository.dart';
import 'widgets/profile_components.dart';

class ProfileNotificationSettingsPage extends StatefulWidget {
  const ProfileNotificationSettingsPage({super.key});

  @override
  State<ProfileNotificationSettingsPage> createState() =>
      _ProfileNotificationSettingsPageState();
}

class _ProfileNotificationSettingsPageState
    extends State<ProfileNotificationSettingsPage> {
  bool? _enabled;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enabled ??=
        context.read<AppSessionController>().settings?.notificationsEnabled ??
            true;
  }

  Future<void> _updateEnabled(bool value) async {
    if (_saving) {
      return;
    }

    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final NotificationSyncService syncService =
        context.read<NotificationSyncService>();
    final UserSettingsModel? current = session.settings;
    if (current == null) {
      return;
    }

    setState(() {
      _saving = true;
      _enabled = value;
    });

    final UserSettingsModel updated =
        current.copyWith(notificationsEnabled: value);
    await repository.saveSettings(updated);
    await syncService.syncForSettings(updated);
    await session.refreshSettings();

    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = _enabled ?? true;
    return ProfileDetailScaffold(
      title: 'Cài đặt thông báo',
      children: <Widget>[
        _NotificationRow(
          title: 'Bật thông báo',
          value: enabled,
          onChanged: _updateEnabled,
        ),
        const SizedBox(height: 14),
        _NotificationRow(
          title: 'Nhắc deadline',
          subtitle: 'Thông báo trước deadline',
          value: enabled,
          onChanged: _updateEnabled,
        ),
        const SizedBox(height: 14),
        _NotificationRow(
          title: 'Nhắc lịch học',
          subtitle: 'Thông báo trước giờ học',
          value: enabled,
          onChanged: _updateEnabled,
        ),
        const SizedBox(height: 14),
        _NotificationRow(
          title: 'Nhắc kế hoạch',
          subtitle: 'Thông báo kế hoạch ôn tập',
          value: enabled,
          onChanged: _updateEnabled,
        ),
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ProfileMenuRow(
      title: title,
      subtitle: subtitle,
      trailing: ProfileToggle(
        value: value,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }
}
