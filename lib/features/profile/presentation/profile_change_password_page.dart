import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/application/app_session_controller.dart';
import '../data/user_settings_repository.dart';
import 'widgets/profile_components.dart';

class ProfileChangePasswordPage extends StatefulWidget {
  const ProfileChangePasswordPage({super.key});

  @override
  State<ProfileChangePasswordPage> createState() =>
      _ProfileChangePasswordPageState();
}

class _ProfileChangePasswordPageState extends State<ProfileChangePasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }

    final AppSessionController session = context.read<AppSessionController>();
    final UserSettingsRepository repository =
        context.read<UserSettingsRepository>();
    if (session.settings == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await repository.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      await session.refreshSettings();
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
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
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSessionController>().settings;
    if (settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ProfileDetailScaffold(
      title: 'Đổi mật khẩu',
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ProfileInfoShell(
                label: 'Mật khẩu hiện tại',
                child: ProfileTextField(
                  controller: _currentPasswordController,
                  hintText: 'Nhập mật khẩu hiện tại',
                  obscureText: true,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nhập mật khẩu hiện tại';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              ProfileInfoShell(
                label: 'Mật khẩu mới',
                child: ProfileTextField(
                  controller: _newPasswordController,
                  hintText: 'Tối thiểu 8 ký tự',
                  obscureText: true,
                  validator: (String? value) {
                    if (value == null || value.trim().length < 8) {
                      return 'Mật khẩu mới tối thiểu 8 ký tự';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              ProfileInfoShell(
                label: 'Xác nhận mật khẩu mới',
                child: ProfileTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Nhập lại mật khẩu mới',
                  obscureText: true,
                  validator: (String? value) {
                    if (value != _newPasswordController.text) {
                      return 'Mật khẩu xác nhận chưa khớp';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 44),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      Color(0xFF93C5FD),
                      Color(0xFF2563EB),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextButton(
                  onPressed: _saving ? null : _save,
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(
                    _saving ? 'Đang lưu...' : 'Đổi mật khẩu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
