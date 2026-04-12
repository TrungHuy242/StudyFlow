import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/studyflow_components.dart';
import '../application/app_session_controller.dart';
import 'auth_flow_payloads.dart';
import 'widgets/auth_scaffold.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.payload,
  });

  final Object? payload;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      6,
      (_) => TextEditingController(),
    );
    _focusNodes = List<FocusNode>.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    for (final FocusNode node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    final String code = _controllers.map((TextEditingController c) => c.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the full 6-digit code.')),
      );
      return;
    }

    final Object? payload = widget.payload;
    if (payload is RegisterDraft) {
      await context.read<AppSessionController>().register(
            displayName: payload.displayName,
            email: payload.email,
            password: payload.password,
          );
      if (!mounted) {
        return;
      }
      context.go('/home');
      return;
    }

    if (payload is ResetPasswordDraft) {
      if (!mounted) {
        return;
      }
      context.push('/reset-password', extra: payload);
      return;
    }

    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  void _handleCodeChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verify email',
      subtitle: 'Enter the verification code sent to your email.',
      badgeIcon: Icons.mark_email_read_outlined,
      onBack: () => context.pop(),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(6, (int index) {
              return SizedBox(
                width: 48,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: Theme.of(context).textTheme.titleLarge,
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: (String value) => _handleCodeChanged(index, value),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Text(
            'Code expires in 02:00',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          StudyFlowGradientButton(
            label: 'Verify',
            onTap: _verify,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification code sent again.')),
              );
            },
            child: const Text("Didn't receive the code? Resend"),
          ),
        ],
      ),
    );
  }
}
