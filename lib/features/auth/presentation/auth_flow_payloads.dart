class RegisterDraft {
  const RegisterDraft({
    required this.displayName,
    required this.studentCode,
    required this.email,
    required this.password,
  });

  final String displayName;
  final String studentCode;
  final String email;
  final String password;
}

class ResetPasswordDraft {
  const ResetPasswordDraft({required this.email});

  final String email;
}
