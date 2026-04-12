import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/studyflow_components.dart';
import 'auth_flow_payloads.dart';
import 'widgets/auth_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _studentCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    context.push(
      '/verify-email',
      extra: RegisterDraft(
        displayName: _nameController.text.trim(),
        studentCode: _studentCodeController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create account',
      subtitle: 'Set up your local StudyFlow account to get started.',
      onBack: () => context.pop(),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            StudyFlowInput(
              controller: _nameController,
              label: 'Full name',
              hintText: 'Nguyen Van A',
              prefixIcon: Icons.person_outline_rounded,
              validator: (String? value) {
                if (value == null || value.trim().length < 2) {
                  return 'Enter a valid full name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            StudyFlowInput(
              controller: _studentCodeController,
              label: 'Student ID',
              hintText: 'B21DCCN123',
              prefixIcon: Icons.badge_outlined,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your student ID.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            StudyFlowInput(
              controller: _passwordController,
              label: 'Password',
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
            const SizedBox(height: 18),
            StudyFlowGradientButton(
              label: 'Create account',
              onTap: _continue,
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Already have an account?',
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
