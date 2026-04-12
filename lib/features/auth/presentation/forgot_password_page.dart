import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/studyflow_components.dart';
import '../application/app_session_controller.dart';
import 'auth_flow_payloads.dart';
import 'widgets/auth_scaffold.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String email = _emailController.text.trim();
    final String storedEmail =
        context.read<AppSessionController>().settings?.email.trim().toLowerCase() ?? '';
    if (storedEmail.isNotEmpty && storedEmail != email.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This email is not registered on this device.'),
        ),
      );
      return;
    }

    context.push(
      '/verify-email',
      extra: ResetPasswordDraft(email: email),
    );
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
              label: 'Send verification code',
              onTap: _continue,
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
