import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/studyflow_components.dart';
import '../application/app_session_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Trang "Quên mật khẩu" (Forgot Password)
///
/// Cho phép người dùng nhập email để nhận mã đặt lại mật khẩu.
/// Sử dụng AuthScaffold để giữ giao diện thống nhất với các màn hình auth khác.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  
  // Key để quản lý trạng thái Form (validate)
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controller cho trường nhập email
  final TextEditingController _emailController = TextEditingController();
  
  // Trạng thái đang gửi yêu cầu (để disable button và hiển thị loading)
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Xử lý sự kiện khi người dùng nhấn nút "Send verification code"
  Future<void> _continue() async {
    // Kiểm tra form có hợp lệ không
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Bắt đầu trạng thái loading
    setState(() {
      _submitting = true;
    });

    try {
      // Gọi controller để gửi yêu cầu đặt lại mật khẩu
      await context.read<AppSessionController>().requestPasswordReset(
            email: _emailController.text.trim(),
          );

      if (!mounted) return;

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email đặt lại mật khẩu đã được gửi.'),
        ),
      );

      // Quay về trang Login sau khi gửi email thành công
      context.go('/login');
      
    } on FormatException catch (error) {
      if (!mounted) return;

      // Hiển thị lỗi từ server hoặc validation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      // Luôn tắt trạng thái loading dù thành công hay thất bại
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
      onBack: () => context.pop(),        // Nút quay lại
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            // Trường nhập email
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

            // Nút gửi mã xác thực
            StudyFlowGradientButton(
              label: _submitting ? 'Đang gửi...' : 'Send verification code',
              onTap: _submitting ? null : _continue,   // Disable khi đang submitting
            ),
          ],
        ),
      ),
      // Phần footer với link quay về đăng nhập
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