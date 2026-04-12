import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_section_card.dart';
import '../../auth/application/app_session_controller.dart';
import '../../notifications/notification_sync_service.dart';
import '../data/user_settings_model.dart';
import '../data/user_settings_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _focusController = TextEditingController();
  final TextEditingController _shortBreakController = TextEditingController();
  final TextEditingController _longBreakController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final UserSettingsModel? settings = context.read<AppSessionController>().settings;
    if (settings != null) {
      _displayNameController.text = settings.displayName;
      _emailController.text = settings.email;
      _focusController.text = settings.focusDuration.toString();
      _shortBreakController.text = settings.shortBreakDuration.toString();
      _longBreakController.text = settings.longBreakDuration.toString();
      _goalController.text = settings.studyGoalMinutes.toString();
      _darkMode = settings.darkMode;
      _notificationsEnabled = settings.notificationsEnabled;
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _focusController.dispose();
    _shortBreakController.dispose();
    _longBreakController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository settingsRepository =
        context.read<UserSettingsRepository>();
    final NotificationSyncService notificationSyncService =
        context.read<NotificationSyncService>();
    final UserSettingsModel? current = session.settings;
    if (current == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final UserSettingsModel updated = current.copyWith(
      displayName: _displayNameController.text.trim(),
      email: _emailController.text.trim(),
      darkMode: _darkMode,
      notificationsEnabled: _notificationsEnabled,
      focusDuration: int.parse(_focusController.text.trim()),
      shortBreakDuration: int.parse(_shortBreakController.text.trim()),
      longBreakDuration: int.parse(_longBreakController.text.trim()),
      studyGoalMinutes: int.parse(_goalController.text.trim()),
    );

    await settingsRepository.saveSettings(updated);
    await notificationSyncService.syncForSettings(updated);
    await session.refreshSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved.')),
    );
  }

  Future<void> _logout() async {
    final AppSessionController sessionController = context.read<AppSessionController>();
    final bool confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Log out?',
      message: 'You can sign back in with your local email and password.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    await sessionController.logout();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final UserSettingsModel? settings = context.watch<AppSessionController>().settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          children: <Widget>[
            AppSectionCard(
              title: settings?.displayName ?? 'Student',
              subtitle: settings?.email.isNotEmpty == true
                  ? settings!.email
                  : 'Local account',
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(labelText: 'Display name'),
                    validator: (String? value) {
                      if (value == null || value.trim().length < 2) {
                        return 'Enter a display name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.itemSpacing),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (String? value) {
                      if (value == null || !value.contains('@')) {
                        return 'Enter a valid email.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.sectionSpacing),
            AppSectionCard(
              title: 'Preferences',
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _darkMode,
                    title: const Text('Dark mode'),
                    onChanged: (bool value) {
                      setState(() {
                        _darkMode = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _notificationsEnabled,
                    title: const Text('Notifications enabled'),
                    onChanged: (bool value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.sectionSpacing),
            AppSectionCard(
              title: 'Focus defaults',
              subtitle: 'Used by Pomodoro and planning screens.',
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _focusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Focus duration (min)'),
                    validator: _minutesValidator,
                  ),
                  const SizedBox(height: AppConstants.itemSpacing),
                  TextFormField(
                    controller: _shortBreakController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Short break (min)'),
                    validator: _minutesValidator,
                  ),
                  const SizedBox(height: AppConstants.itemSpacing),
                  TextFormField(
                    controller: _longBreakController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Long break (min)'),
                    validator: _minutesValidator,
                  ),
                  const SizedBox(height: AppConstants.itemSpacing),
                  TextFormField(
                    controller: _goalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Study goal per day (min)'),
                    validator: _minutesValidator,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.sectionSpacing),
            AppSectionCard(
              title: 'Shortcuts',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ActionChip(
                    label: const Text('Semester'),
                    onPressed: () => context.push('/semester'),
                  ),
                  ActionChip(
                    label: const Text('Subjects'),
                    onPressed: () => context.push('/subjects'),
                  ),
                  ActionChip(
                    label: const Text('Notifications'),
                    onPressed: () => context.push('/notifications'),
                  ),
                  ActionChip(
                    label: const Text('Analytics'),
                    onPressed: () => context.push('/analytics'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.sectionSpacing),
            FilledButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: Text(_isSaving ? 'Saving...' : 'Save changes'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _logout,
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  String? _minutesValidator(String? value) {
    final int? minutes = int.tryParse(value ?? '');
    if (minutes == null || minutes <= 0) {
      return 'Enter a valid number.';
    }
    return null;
  }
}
