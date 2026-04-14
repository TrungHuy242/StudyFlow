import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/application/app_session_controller.dart';
import '../../notifications/notification_sync_service.dart';
import '../data/user_settings_model.dart';
import '../data/user_settings_repository.dart';
import 'widgets/profile_components.dart';

class ProfileAppSettingsPage extends StatefulWidget {
  const ProfileAppSettingsPage({super.key});

  @override
  State<ProfileAppSettingsPage> createState() => _ProfileAppSettingsPageState();
}

class _ProfileAppSettingsPageState extends State<ProfileAppSettingsPage> {
  bool? _soundEnabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _soundEnabled ??=
        context.read<AppSessionController>().settings?.notificationsEnabled ??
            true;
  }

  Future<void> _updateSound(bool value) async {
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
      _soundEnabled = value;
    });

    final UserSettingsModel updated =
        current.copyWith(notificationsEnabled: value);
    await repository.saveSettings(updated);
    await syncService.syncForSettings(updated);
    await session.refreshSettings();
  }

  Future<void> _editMinutes({
    required String title,
    required int initialValue,
    required Future<void> Function(int value) applyUpdate,
  }) async {
    final int? result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return _MinutesInputDialog(
          title: title,
          initialValue: initialValue,
        );
      },
    );

    if (result == null || result <= 0) {
      return;
    }

    await applyUpdate(result);
  }

  Future<void> _updateFocusDuration(int value) async {
    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final UserSettingsModel? current = session.settings;
    if (current == null) {
      return;
    }
    await repository.saveSettings(current.copyWith(focusDuration: value));
    await session.refreshSettings();
  }

  Future<void> _updateShortBreakDuration(int value) async {
    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final UserSettingsModel? current = session.settings;
    if (current == null) {
      return;
    }
    await repository.saveSettings(current.copyWith(shortBreakDuration: value));
    await session.refreshSettings();
  }

  Future<void> _updateLongBreakDuration(int value) async {
    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final UserSettingsModel? current = session.settings;
    if (current == null) {
      return;
    }
    await repository.saveSettings(current.copyWith(longBreakDuration: value));
    await session.refreshSettings();
  }

  Future<void> _updateStudyGoal(int value) async {
    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final UserSettingsModel? current = session.settings;
    if (current == null) {
      return;
    }
    await repository.saveSettings(current.copyWith(studyGoalMinutes: value));
    await session.refreshSettings();
  }

  @override
  Widget build(BuildContext context) {
    final UserSettingsModel? settings =
        context.watch<AppSessionController>().settings;
    if (settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ProfileDetailScaffold(
      title: 'Cài đặt ứng dụng',
      children: <Widget>[
        ProfileMenuRow(
          title: 'Âm thanh',
          trailing: ProfileToggle(
            value: _soundEnabled ?? settings.notificationsEnabled,
            onChanged: _updateSound,
          ),
          onTap: () =>
              _updateSound(!(_soundEnabled ?? settings.notificationsEnabled)),
        ),
        const SizedBox(height: 14),
        const ProfileMenuRow(
          title: 'Tự động bắt đầu',
          subtitle: 'Pomodoro',
          trailing: ProfileToggle(
            value: false,
            onChanged: null,
            enabled: false,
          ),
        ),
        const SizedBox(height: 14),
        ProfileMenuRow(
          title: 'Thời gian Pomodoro',
          subtitle: '${settings.focusDuration} phút',
          onTap: () => _editMinutes(
            title: 'Thời gian Pomodoro',
            initialValue: settings.focusDuration,
            applyUpdate: _updateFocusDuration,
          ),
        ),
        const SizedBox(height: 14),
        ProfileMenuRow(
          title: 'Thời gian nghỉ',
          subtitle: '${settings.shortBreakDuration} phút',
          onTap: () => _editMinutes(
            title: 'Thời gian nghỉ',
            initialValue: settings.shortBreakDuration,
            applyUpdate: _updateShortBreakDuration,
          ),
        ),
        const SizedBox(height: 14),
        ProfileMenuRow(
          title: 'Thời gian nghỉ dài',
          subtitle: '${settings.longBreakDuration} phút',
          onTap: () => _editMinutes(
            title: 'Thời gian nghỉ dài',
            initialValue: settings.longBreakDuration,
            applyUpdate: _updateLongBreakDuration,
          ),
        ),
        const SizedBox(height: 14),
        ProfileMenuRow(
          title: 'Mục tiêu học mỗi ngày',
          subtitle: '${settings.studyGoalMinutes} phút',
          onTap: () => _editMinutes(
            title: 'Mục tiêu học mỗi ngày',
            initialValue: settings.studyGoalMinutes,
            applyUpdate: _updateStudyGoal,
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            '${AppConstants.appName} v1.0.0',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _MinutesInputDialog extends StatefulWidget {
  const _MinutesInputDialog({
    required this.title,
    required this.initialValue,
  });

  final String title;
  final int initialValue;

  @override
  State<_MinutesInputDialog> createState() => _MinutesInputDialogState();
}

class _MinutesInputDialogState extends State<_MinutesInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Nhập số phút'),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(int.tryParse(_controller.text.trim())),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
