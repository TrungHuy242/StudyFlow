import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/studyflow_palette.dart';
import '../../../shared/widgets/studyflow_components.dart';
import '../application/app_session_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Trang Đăng nhập (Login Page)
///
/// Đây là màn hình chính để người dùng đăng nhập vào ứng dụng.
/// Sử dụng AuthScaffold để giữ giao diện thống nhất với các màn hình xác thực khác.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  
  // Key quản lý trạng thái Form (dùng để validate)
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controller cho hai trường nhập liệu
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Trạng thái ẩn/hiện mật khẩu
  bool _obscurePassword = true;
  
  // Trạng thái đang xử lý đăng nhập (để disable button và hiển thị loading)
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý logic đăng nhập khi người dùng nhấn nút "Đăng nhập"
  Future<void> _submit() async {
    // Kiểm tra form có hợp lệ không
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final AppSessionController session = context.read<AppSessionController>();

    // Bắt đầu trạng thái loading
    setState(() {
      _submitting = true;
    });

    try {
      // Gọi hàm login từ AppSessionController
      await session.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Đăng nhập thành công → chuyển hướng về trang chủ
      context.go('/home');
      
    } on FormatException catch (error) {
      if (!mounted) return;

      // Hiển thị lỗi từ server (ví dụ: sai email/mật khẩu)
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

  /// Hiển thị thông báo placeholder cho chức năng đăng nhập bằng mạng xã hội
  /// (Hiện tại chỉ là demo, sẽ triển khai thật ở phiên bản sau)
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
            // Trường nhập Email
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

            // Trường nhập Mật khẩu
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

            // Link "Quên mật khẩu?"
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: 12),

            // Nút Đăng nhập chính
            StudyFlowGradientButton(
              label: _submitting ? 'Đang đăng nhập...' : 'Đăng nhập',
              onTap: _submitting ? null : _submit,   // Disable nút khi đang xử lý
            ),
            const SizedBox(height: 28),

            // Phân cách "Hoặc đăng nhập với"
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

            // Hai nút đăng nhập bằng Google và GitHub (chưa triển khai thật)
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
      // Phần footer: Link chuyển sang trang Đăng ký
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