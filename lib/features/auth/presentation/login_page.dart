import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../application/app_session_controller.dart';
import 'widgets/auth_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AppSessionController session = context.read<AppSessionController>();
    setState(() {
      _submitting = true;
    });
    try {
      await session.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      context.go('/home');
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showPlaceholderSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider sẽ được kết nối ở bản sau.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Đăng nhập',
      subtitle: 'Chào mừng bạn quay trở lại!',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StudyFlowInput(
              controller: _emailController,
              label: 'Email',
              hintText: 'student@university.edu.vn',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || !value.contains('@')) {
                  return 'Nhập email hợp lệ.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            StudyFlowInput(
              controller: _passwordController,
              label: 'Mật khẩu',
              hintText: 'Nhập mật khẩu',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              onSuffixTap: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              obscureText: _obscurePassword,
              validator: (String? value) {
                if (value == null || value.length < 6) {
                  return 'Mật khẩu phải có ít nhất 6 ký tự.';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: 12),
            StudyFlowGradientButton(
              label: _submitting ? 'Đang đăng nhập...' : 'Đăng nhập',
              onTap: _submitting ? null : _submit,
            ),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                const Expanded(child: Divider(color: StudyFlowPalette.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Hoặc đăng nhập với',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Expanded(child: Divider(color: StudyFlowPalette.border)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: StudyFlowOutlineButton(
                    label: 'Google',
                    icon: Icons.g_mobiledata_rounded,
                    onTap: () => _showPlaceholderSocialLogin('Google'),
                    height: 56,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StudyFlowOutlineButton(
                    label: 'GitHub',
                    icon: Icons.code_rounded,
                    onTap: () => _showPlaceholderSocialLogin('GitHub'),
                    height: 56,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Chưa có tài khoản?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => context.push('/register'),
            child: const Text('Đăng ký ngay'),
          ),
        ],
      ),
    );
  }
}
