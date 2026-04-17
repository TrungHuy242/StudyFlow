import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/application/app_session_controller.dart';
import '../../notifications/notification_sync_service.dart';
import '../data/user_settings_model.dart';
import '../data/user_settings_repository.dart';
import 'widgets/profile_components.dart';

/// Trang Cài đặt Ứng dụng (App Settings)
///
/// Cho phép người dùng tùy chỉnh các thiết lập liên quan đến:
/// - Âm thanh thông báo
/// - Thời gian Pomodoro (focus, short break, long break)
/// - Mục tiêu học tập mỗi ngày
class ProfileAppSettingsPage extends StatefulWidget {
  const ProfileAppSettingsPage({super.key});

  @override
  State<ProfileAppSettingsPage> createState() => _ProfileAppSettingsPageState();
}

class _ProfileAppSettingsPageState extends State<ProfileAppSettingsPage> {
  
  // Trạng thái cục bộ cho toggle Âm thanh (dùng để cập nhật UI ngay lập tức)
  bool? _soundEnabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lấy giá trị ban đầu từ AppSessionController (chỉ lấy 1 lần)
    _soundEnabled ??=
        context.read<AppSessionController>().settings?.notificationsEnabled ??
            true;
  }

  /// Cập nhật trạng thái bật/tắt âm thanh thông báo
  Future<void> _updateSound(bool value) async {
    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final NotificationSyncService syncService =
        context.read<NotificationSyncService>();

    final UserSettingsModel? current = session.settings;
    if (current == null) return;

    // Cập nhật UI ngay lập tức (optimistic update)
    setState(() {
      _soundEnabled = value;
    });

    final UserSettingsModel updated =
        current.copyWith(notificationsEnabled: value);

    try {
      // Lưu vào repository
      await repository.saveSettings(updated);
      
      // Đồng bộ thông báo (nếu có service push notification)
      await syncService.syncForSettings(updated);
      
      // Làm mới dữ liệu trong session
      await session.refreshSettings();
    } on FormatException catch (error) {
      if (!mounted) return;

      // Rollback UI nếu lỗi
      setState(() {
        _soundEnabled = current.notificationsEnabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  /// Hiển thị dialog nhập số phút và xử lý cập nhật
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

  /// Cập nhật thời gian tập trung (Pomodoro Focus)
  Future<void> _updateFocusDuration(int value) async {
    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final UserSettingsModel? current = session.settings;
    if (current == null) return;

    try {
      await repository.saveSettings(current.copyWith(focusDuration: value));
      await session.refreshSettings();
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  /// Cập nhật thời gian nghỉ ngắn
  Future<void> _updateShortBreakDuration(int value) async {
    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final UserSettingsModel? current = session.settings;
    if (current == null) return;

    try {
      await repository.saveSettings(
        current.copyWith(shortBreakDuration: value),
      );
      await session.refreshSettings();
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  /// Cập nhật thời gian nghỉ dài
  Future<void> _updateLongBreakDuration(int value) async {
    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final UserSettingsModel? current = session.settings;
    if (current == null) return;

    try {
      await repository.saveSettings(current.copyWith(longBreakDuration: value));
      await session.refreshSettings();
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  /// Cập nhật mục tiêu học tập mỗi ngày (phút)
  Future<void> _updateStudyGoal(int value) async {
    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final UserSettingsModel? current = session.settings;
    if (current == null) return;

    try {
      await repository.saveSettings(current.copyWith(studyGoalMinutes: value));
      await session.refreshSettings();
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserSettingsModel? settings =
        context.watch<AppSessionController>().settings;

    // Hiển thị loading nếu chưa có dữ liệu settings
    if (settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ProfileDetailScaffold(
      title: 'Cài đặt ứng dụng',
      children: <Widget>[
        // Toggle Âm thanh thông báo
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

        // Tự động bắt đầu Pomodoro (chưa hỗ trợ)
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

        // Thời gian Pomodoro (Focus)
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

        // Thời gian nghỉ ngắn
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

        // Thời gian nghỉ dài
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

        // Mục tiêu học mỗi ngày
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

        // Phiên bản ứng dụng
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

/// Dialog nhập số phút (dùng cho Pomodoro, nghỉ, mục tiêu...)
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