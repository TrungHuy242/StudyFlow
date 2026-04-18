import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/studyflow_components.dart';
import '../application/app_session_controller.dart';
import 'auth_flow_payloads.dart';
import 'widgets/auth_scaffold.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.draft,
  });

  final ResetPasswordDraft? draft;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ResetPasswordDraft? draft = widget.draft;
    if (draft == null) {
      context.go('/login');
      return;
    }

    try {
      await context.read<AppSessionController>().resetPassword(
            email: draft.email,
            newPassword: _passwordController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      context.go('/login');
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset password',
      subtitle: 'Create a new password for your local account.',
      badgeIcon: Icons.lock_reset_rounded,
      onBack: () => context.pop(),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            StudyFlowInput(
              controller: _passwordController,
              label: 'New password',
              hintText: 'At least 8 characters',
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
                if (value == null || value.length < 8) {
                  return 'Password must be at least 8 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            StudyFlowInput(
              controller: _confirmController,
              label: 'Confirm password',
              hintText: 'Re-enter your new password',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: _obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              onSuffixTap: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
              obscureText: _obscureConfirm,
              validator: (String? value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const StudyFlowSurfaceCard(
              padding: EdgeInsets.all(18),
              color: Color(0xFFF9FAFF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Your password should include:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 12),
                  _PasswordRule('At least 8 characters'),
                  SizedBox(height: 8),
                  _PasswordRule('At least 1 uppercase letter'),
                  SizedBox(height: 8),
                  _PasswordRule('At least 1 number'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            StudyFlowGradientButton(
              label: 'Reset password',
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  const _PasswordRule(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 18,
          color: Color(0xFF8FA0BC),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
