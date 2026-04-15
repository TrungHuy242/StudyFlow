import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/studyflow_components.dart';
import '../../auth/application/app_session_controller.dart';
import '../../profile/data/user_settings_model.dart';
import '../../profile/data/user_settings_repository.dart';
import '../notification_sync_service.dart';
import 'widgets/notification_form_sheet.dart';

class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  bool? _notificationsEnabled;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationsEnabled ??=
        context.read<AppSessionController>().settings?.notificationsEnabled ?? true;
  }

  Future<void> _updateSetting(bool value) async {
    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository = context.read<UserSettingsRepository>();
    final NotificationSyncService syncService = context.read<NotificationSyncService>();
    final UserSettingsModel? current = session.settings;
    if (current == null || _saving) {
      return;
    }

    setState(() {
      _saving = true;
      _notificationsEnabled = value;
    });

    final UserSettingsModel updated = current.copyWith(notificationsEnabled: value);
    try {
      await repository.saveSettings(updated);
      await syncService.syncForSettings(updated);
      await session.refreshSettings();
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _notificationsEnabled = current.notificationsEnabled;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = _notificationsEnabled ?? true;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                StudyFlowCircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  size: 42,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    'Cài đặt nhắc nhở',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 42),
              ],
            ),
            const SizedBox(height: 28),
            _ReminderSettingRow(
              title: 'Nhắc deadline',
              subtitle: 'Trước 1 giờ',
              value: enabled,
              onChanged: _updateSetting,
            ),
            _ReminderSettingRow(
              title: 'Nhắc lịch học',
              subtitle: 'Trước 15 phút',
              value: enabled,
              onChanged: _updateSetting,
            ),
            _ReminderSettingRow(
              title: 'Nhắc Flashcard',
              subtitle: 'Hàng ngày lúc 19:00',
              value: enabled,
              onChanged: _updateSetting,
            ),
            _ReminderSettingRow(
              title: 'Nhắc Pomodoro',
              subtitle: 'Mỗi 25 phút',
              value: enabled,
              onChanged: _updateSetting,
            ),
            _ReminderSettingRow(
              title: 'Âm thanh thông báo',
              subtitle: 'Mặc định hệ thống',
              value: enabled,
              onChanged: _updateSetting,
            ),
            _ReminderSettingRow(
              title: 'Rung khi thông báo',
              value: enabled,
              onChanged: _updateSetting,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderSettingRow extends StatelessWidget {
  const _ReminderSettingRow({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                  ),
                ],
              ],
            ),
          ),
          ReminderToggle(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
