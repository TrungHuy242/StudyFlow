import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/application/app_session_controller.dart';
import '../data/user_settings_model.dart';
import '../data/user_settings_repository.dart';
import 'widgets/profile_components.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final UserSettingsModel? settings =
        context.read<AppSessionController>().settings;
    if (settings != null) {
      _displayNameController.text = settings.displayName;
      _emailController.text = settings.email;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
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
      _saving = true;
    });

    final UserSettingsModel updated = current.copyWith(
      displayName: _displayNameController.text.trim(),
      email: _emailController.text.trim(),
    );

    await repository.saveSettings(updated);
    await session.refreshSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });
    Navigator.of(context).pop(true);
  }

  void _showAvatarComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đổi ảnh đại diện sẽ được hỗ trợ ở bản cập nhật sau.'),
      ),
    );
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
      title: 'Chỉnh sửa hồ sơ',
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    ProfileAvatarBadge(
                      name: _displayNameController.text.isEmpty
                          ? settings.displayName
                          : _displayNameController.text,
                      size: 92,
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _showAvatarComingSoon,
                      child: const Text(
                        'Đổi ảnh đại diện',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ProfileInfoShell(
                label: 'Họ và tên',
                child: ProfileTextField(
                  controller: _displayNameController,
                  hintText: 'Nguyễn Văn Sinh Viên',
                  validator: (String? value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Nhập họ tên hợp lệ';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              ProfileInfoShell(
                label: 'Email',
                child: ProfileTextField(
                  controller: _emailController,
                  hintText: 'student@university.edu.vn',
                  keyboardType: TextInputType.emailAddress,
                  validator: (String? value) {
                    if (value == null || !value.contains('@')) {
                      return 'Nhập email hợp lệ';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              ProfileInfoShell(
                label: 'Mã sinh viên',
                child: Text(
                  profileStudentId(settings),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              ProfileActionButtons(
                primaryLabel: _saving ? 'Đang lưu...' : 'Lưu',
                onPrimary: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
