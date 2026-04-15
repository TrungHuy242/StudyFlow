import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/studyflow_components.dart';
import '../application/app_session_controller.dart';
import 'widgets/auth_scaffold.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await context.read<AppSessionController>().requestPasswordReset(
            email: _emailController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email đặt lại mật khẩu đã được gửi.'),
        ),
      );
      context.go('/login');
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot password?',
      subtitle: 'Enter your email to recover access to your local account.',
      onBack: () => context.pop(),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            StudyFlowInput(
              controller: _emailController,
              label: 'Email',
              hintText: 'student@university.edu.vn',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (String? value) {
                if (value == null || !value.contains('@')) {
                  return 'Enter a valid email.';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            StudyFlowGradientButton(
              label: _submitting ? 'Đang gửi...' : 'Send verification code',
              onTap: _submitting ? null : _continue,
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Remembered your password?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
