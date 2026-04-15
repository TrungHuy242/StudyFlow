import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/application/app_session_controller.dart';
import '../data/user_settings_model.dart';
import '../data/user_settings_repository.dart';
import 'widgets/profile_components.dart';

enum _ThemeChoice { light, dark, system }

class ProfileThemePage extends StatefulWidget {
  const ProfileThemePage({super.key});

  @override
  State<ProfileThemePage> createState() => _ProfileThemePageState();
}

class _ProfileThemePageState extends State<ProfileThemePage> {
  _ThemeChoice _choice = _ThemeChoice.light;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final bool darkMode =
        context.read<AppSessionController>().settings?.darkMode ?? false;
    _choice = darkMode ? _ThemeChoice.dark : _ThemeChoice.light;
    _initialized = true;
  }

  Future<void> _setTheme(_ThemeChoice value) async {
    if (value == _ThemeChoice.system) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Chế độ theo hệ thống sẽ được hỗ trợ ở bản cập nhật sau.'),
        ),
      );
      return;
    }

    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    final UserSettingsModel? current = session.settings;
    if (current == null) {
      return;
    }

    setState(() {
      _choice = value;
    });

    final UserSettingsModel updated = current.copyWith(
      darkMode: value == _ThemeChoice.dark,
    );
    try {
      await repository.saveSettings(updated);
      await session.refreshSettings();
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _choice = current.darkMode ? _ThemeChoice.dark : _ThemeChoice.light;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileDetailScaffold(
      title: 'Giao diện',
      children: <Widget>[
        const SizedBox(height: 36),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: <Widget>[
              ThemeOptionCard(
                label: 'Sáng',
                selected: _choice == _ThemeChoice.light,
                onTap: () => _setTheme(_ThemeChoice.light),
              ),
              const SizedBox(width: 10),
              ThemeOptionCard(
                label: 'Tối',
                selected: _choice == _ThemeChoice.dark,
                onTap: () => _setTheme(_ThemeChoice.dark),
              ),
              const SizedBox(width: 10),
              ThemeOptionCard(
                label: 'Theo hệ thống',
                selected: _choice == _ThemeChoice.system,
                enabled: false,
                onTap: () => _setTheme(_ThemeChoice.system),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
