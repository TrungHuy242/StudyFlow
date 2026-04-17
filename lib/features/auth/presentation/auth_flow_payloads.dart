/// Lớp lưu trữ thông tin tạm thời (draft) khi người dùng đang điền form Đăng ký.
///
/// Sử dụng để truyền dữ liệu giữa các màn hình hoặc giữ trạng thái form 
/// trong quá trình đăng ký (ví dụ: từ màn hình nhập thông tin cá nhân sang màn hình xác nhận).
class RegisterDraft {
  
  const RegisterDraft({
    required this.displayName,
    required this.studentCode,
    required this.email,
    required this.password,
  });

  /// Tên hiển thị của người dùng (ví dụ: Nguyễn Văn A)
  final String displayName;

  /// Mã số sinh viên (Student ID)
  final String studentCode;

  /// Địa chỉ email dùng để đăng ký tài khoản
  final String email;

  /// Mật khẩu người dùng muốn đặt
  final String password;
}

/// Lớp lưu trữ thông tin tạm thời dùng cho chức năng Quên mật khẩu / Đặt lại mật khẩu.
///
/// Thường được sử dụng để truyền email từ màn hình "Quên mật khẩu" 
/// sang màn hình "Nhập mã OTP" hoặc "Đặt mật khẩu mới".
class ResetPasswordDraft {
  
  const ResetPasswordDraft({required this.email});

  /// Email của người dùng cần đặt lại mật khẩu
  final String email;
}