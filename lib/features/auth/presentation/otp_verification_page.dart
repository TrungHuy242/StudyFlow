import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/studyflow_components.dart';
import '../application/app_session_controller.dart';
import 'auth_flow_payloads.dart';
import 'widgets/auth_scaffold.dart';

/// Trang Xác thực OTP (OtpVerificationPage)
///
/// Màn hình này dùng để người dùng nhập mã OTP (6 số) được gửi về email.
/// Hỗ trợ hai luồng chính:
/// 1. Xác thực sau khi đăng ký (Register → OTP → Hoàn tất đăng ký)
/// 2. Xác thực trước khi đặt lại mật khẩu (Forgot Password → OTP → Reset Password)
class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.payload,
  });

  /// Dữ liệu được truyền từ màn hình trước đó
  /// Có thể là `RegisterDraft` hoặc `ResetPasswordDraft`
  final Object? payload;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  
  // Mã OTP giả lập dùng cho mục đích phát triển (demo)
  static const String _acceptedOtpCode = '123456';

  // Danh sách 6 TextEditingController cho từng ô nhập OTP
  late final List<TextEditingController> _controllers;
  
  // Danh sách 6 FocusNode để tự động chuyển focus giữa các ô
  late final List<FocusNode> _focusNodes;

  // Trạng thái đang xác thực OTP
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Tạo 6 controller và 6 focus node
    _controllers = List<TextEditingController>.generate(
      6,
      (_) => TextEditingController(),
    );
    _focusNodes = List<FocusNode>.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ cho tất cả controller và focus node
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    for (final FocusNode node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Xử lý logic xác thực OTP
  Future<void> _verify() async {
    // Ghép 6 số lại thành một chuỗi OTP
    final String code = _controllers
        .map((TextEditingController controller) => controller.text)
        .join();

    // Kiểm tra mã OTP (hiện đang dùng mã giả lập)
    if (code != _acceptedOtpCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã OTP không đúng. Vui lòng nhập 123456.'),
        ),
      );
      return;
    }

    final Object? payload = widget.payload;

    // === LUỒNG 1: Xác thực sau khi đăng ký ===
    if (payload is RegisterDraft) {
      setState(() => _submitting = true);

      try {
        await context.read<AppSessionController>().register(
              displayName: payload.displayName,
              studentCode: payload.studentCode,
              email: payload.email,
              password: payload.password,
            );

        if (!mounted) return;

        // Đăng ký thành công → chuyển về trang chủ
        context.go('/home');
      } on FormatException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      } finally {
        if (mounted) {
          setState(() => _submitting = false);
        }
      }
      return;
    }

    // === LUỒNG 2: Xác thực trước khi đặt lại mật khẩu ===
    if (payload is ResetPasswordDraft) {
      if (!mounted) return;
      // Chuyển sang màn hình đặt mật khẩu mới và truyền payload
      context.push('/reset-password', extra: payload);
      return;
    }

    // Trường hợp không xác định được payload → quay về Login
    if (!mounted) return;
    context.go('/login');
  }

  /// Xử lý khi người dùng nhập ký tự vào ô OTP
  /// - Tự động chuyển sang ô tiếp theo khi nhập xong
  /// - Tự động quay về ô trước khi xóa
  /// - Giới hạn chỉ nhập 1 ký tự mỗi ô
  void _handleCodeChanged(int index, String value) {
    if (value.length > 1) {
      // Chỉ giữ lại ký tự cuối cùng nếu paste nhiều số
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }

    // Chuyển focus sang ô tiếp theo nếu đã nhập
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    // Quay về ô trước nếu xóa ký tự
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  /// Giả lập chức năng gửi lại OTP (chỉ để demo)
  void _resendFakeOtp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi lại OTP giả lập. Mã phát triển vẫn là 123456.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verify email',
      subtitle: 'Enter the verification code sent to your email.',
      badgeIcon: Icons.mark_email_read_outlined,   // Icon thư đã đọc
      onBack: () => context.pop(),
      body: Column(
        children: <Widget>[
          // Hiển thị 6 ô nhập OTP nằm ngang
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

          // Hiển thị mã OTP giả lập để tester dễ kiểm tra
          Text(
            'Mã phát triển: 123456',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),

          // Nút Xác nhận
          StudyFlowGradientButton(
            label: _submitting ? 'Đang xác nhận...' : 'Verify',
            onTap: _submitting ? null : _verify,
          ),
          const SizedBox(height: 20),

          // Link "Gửi lại mã"
          TextButton(
            onPressed: _resendFakeOtp,
            child: const Text("Didn't receive the code? Resend"),
          ),
        ],
      ),
    );
  }
}