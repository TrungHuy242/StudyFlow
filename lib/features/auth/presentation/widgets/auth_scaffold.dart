import 'package:flutter/material.dart';

import '../../../../core/theme/studyflow_palette.dart';
import '../../../../shared/widgets/studyflow_components.dart';

/// Widget Scaffold chung dùng cho tất cả các màn hình Authentication (Xác thực)
///
/// Bao gồm: Login, Register, Forgot Password, Reset Password, Onboarding...
/// 
/// Widget này giúp giữ giao diện nhất quán giữa các màn hình auth, tránh lặp code.
class AuthScaffold extends StatelessWidget {
  
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.badgeIcon = Icons.auto_stories_rounded,
    this.onBack,
    this.footer,
  });

  /// Tiêu đề chính của màn hình (ví dụ: "Đăng nhập", "Tạo tài khoản", ...)
  final String title;

  /// Phụ đề mô tả ngắn gọn bên dưới tiêu đề
  final String subtitle;

  /// Nội dung chính của màn hình (form, text fields, buttons...)
  final Widget body;

  /// Icon hiển thị ở đầu màn hình (mặc định là sách - Icons.auto_stories_rounded)
  final IconData badgeIcon;

  /// Callback khi nhấn nút quay lại (Back)
  /// Nếu truyền null thì sẽ không hiển thị nút back
  final VoidCallback? onBack;

  /// Phần footer nằm ở dưới cùng màn hình (thường là nút "Đăng nhập", "Tiếp tục", 
  /// hoặc link "Chưa có tài khoản? Đăng ký")
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nền trắng cho tất cả màn hình xác thực
      backgroundColor: Colors.white,
      
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Phần nội dung chính có thể cuộn khi bàn phím hiện lên
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    
                    // Nút quay lại (Back) - chỉ hiển thị khi có onBack
                    if (onBack != null) ...<Widget>[
                      StudyFlowCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: onBack,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Icon badge trang trí ở đầu màn hình (hình sách màu indigo)
                    StudyFlowIconBadge(
                      icon: badgeIcon,
                      backgroundColor: StudyFlowPalette.indigo,
                    ),
                    
                    const SizedBox(height: 24),

                    // Tiêu đề lớn
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 22,
                            height: 1.15,
                          ),
                    ),

                    const SizedBox(height: 10),

                    // Phụ đề
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                    ),

                    const SizedBox(height: 28),

                    // Nội dung chính (Form fields, buttons...) được truyền vào
                    body,
                  ],
                ),
              ),
            ),

            // Phần footer nằm cố định ở dưới cùng màn hình
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}