import 'package:supabase/supabase.dart';

import '../../../core/auth/supabase_auth_storage.dart';
import '../../../core/data/user_scope.dart';
import '../../../core/database/database_service.dart';
import '../../../core/utils/date_time_utils.dart';
import 'user_settings_model.dart';

class UserSettingsRepository {
  UserSettingsRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<UserSettingsModel> getSettings() async {
    if (!_databaseService.isAuthenticated) {
      final bool onboardingDone =
          await SupabaseAuthStorage.instance.readOnboardingDone();
      return _guestSettings(onboardingDone: onboardingDone);
    }

    final UserSettingsModel settings = await _ensureUserSettingsRow();
    await SupabaseAuthStorage.instance.writeOnboardingDone(
      settings.onboardingDone,
    );
    return settings;
  }

  Future<UserSettingsModel> saveSettings(UserSettingsModel settings) async {
    final User user = _requireCurrentUser();
    try {
      final String normalizedEmail = settings.email.trim();
      if (normalizedEmail.isNotEmpty &&
          normalizedEmail.toLowerCase() !=
              (user.email ?? '').trim().toLowerCase()) {
        await _databaseService.client.auth.updateUser(
          UserAttributes(email: normalizedEmail),
        );
      }

      final Map<String, dynamic> mergedMetadata = <String, dynamic>{
        ...?user.userMetadata,
        'display_name': settings.displayName.trim(),
        'student_code': (settings.studentCode ?? '').trim(),
      };
      await _databaseService.client.auth.updateUser(
        UserAttributes(data: mergedMetadata),
      );

      await _databaseService.client.from('user_settings').upsert(
        _toPayload(
          user: _databaseService.client.auth.currentUser ?? user,
          settings: settings,
        ),
        onConflict: 'id',
      );

      return _ensureUserSettingsRow();
    } on AuthException catch (error) {
      throw FormatException(_mapAuthError(error));
    }
  }

  Future<UserSettingsModel> completeOnboarding() async {
    await SupabaseAuthStorage.instance.writeOnboardingDone(true);
    if (!_databaseService.isAuthenticated) {
      return _guestSettings(onboardingDone: true);
    }

    final UserSettingsModel current = await _ensureUserSettingsRow();
    return saveSettings(current.copyWith(onboardingDone: true));
  }

  Future<UserSettingsModel> registerAccount({
    required String displayName,
    required String studentCode,
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _databaseService.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, Object?>{
          'display_name': displayName.trim(),
          'student_code': studentCode.trim(),
        },
      );

      if (response.session == null) {
        throw const FormatException(
          'Supabase dang bat xac minh email that. Với moi truong phat trien, hay tat "Confirm email" trong Supabase Auth > Providers > Email.',
        );
      }

      await SupabaseAuthStorage.instance.writeOnboardingDone(true);
      return _ensureUserSettingsRow(
        fallbackDisplayName: displayName.trim(),
        fallbackEmail: email.trim(),
        fallbackStudentCode: studentCode.trim(),
        onboardingDone: true,
      );
    } on AuthException catch (error) {
      throw FormatException(_mapAuthError(error));
    }
  }

  Future<UserSettingsModel> login({
    required String email,
    required String password,
  }) async {
    try {
      await _databaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _ensureUserSettingsRow(fallbackEmail: email.trim());
    } on AuthException catch (error) {
      throw FormatException(_mapAuthError(error));
    }
  }

  Future<UserSettingsModel> logout() async {
    await _databaseService.client.auth.signOut();
    final bool onboardingDone =
        await SupabaseAuthStorage.instance.readOnboardingDone();
    return _guestSettings(onboardingDone: onboardingDone);
  }

  Future<void> requestPasswordReset({
    required String email,
  }) async {
    try {
      await _databaseService.client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (error) {
      throw FormatException(_mapAuthError(error));
    }
  }

  Future<UserSettingsModel> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final User currentUser = _requireCurrentUser();
    final String currentEmail = (currentUser.email ?? '').trim().toLowerCase();
    if (currentEmail.isEmpty || currentEmail != email.trim().toLowerCase()) {
      throw const FormatException(
        'Hay mo lien ket dat lai mat khau tu email dung tai khoan nay truoc.',
      );
    }

    try {
      await _databaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (error) {
      throw FormatException(_mapAuthError(error));
    }

    return _ensureUserSettingsRow();
  }

  Future<UserSettingsModel> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final User currentUser = _requireCurrentUser();
    final String email = (currentUser.email ?? '').trim();
    if (email.isEmpty) {
      throw const FormatException('Tai khoan hien tai khong co email hop le.');
    }

    try {
      await _databaseService.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } on AuthException {
      throw const FormatException('Mat khau hien tai chua dung.');
    }

    try {
      await _databaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (error) {
      throw FormatException(_mapAuthError(error));
    }

    return _ensureUserSettingsRow();
  }

  Future<bool> getLocalOnboardingDone() {
    return SupabaseAuthStorage.instance.readOnboardingDone();
  }

  Future<UserSettingsModel> _ensureUserSettingsRow({
    String? fallbackDisplayName,
    String? fallbackEmail,
    String? fallbackStudentCode,
    bool? onboardingDone,
  }) async {
    final User user = _requireCurrentUser();
    final int rowId = UserScope.profileRowId(user.id);
    final dynamic result = await _databaseService.client
        .from('user_settings')
        .select(
          'id, display_name, email, avatar, dark_mode, notifications_enabled, onboarding_done, focus_duration, short_break_duration, long_break_duration, study_goal_minutes',
        )
        .eq('id', rowId)
        .maybeSingle();

    final bool localOnboardingDone =
        onboardingDone ?? await SupabaseAuthStorage.instance.readOnboardingDone();

    if (result == null) {
      final UserSettingsModel created = UserSettingsModel(
        userId: user.id,
        displayName: _preferredDisplayName(
          fallbackDisplayName,
          user.userMetadata?['display_name']?.toString(),
        ),
        email: _preferredEmail(fallbackEmail, user.email),
        avatar: null,
        studentCode: _preferredStudentCode(
          fallbackStudentCode,
          user.userMetadata?['student_code']?.toString(),
        ),
        joinedAt: DateTimeUtils.tryParse(user.createdAt),
        darkMode: false,
        notificationsEnabled: true,
        onboardingDone: localOnboardingDone,
        focusDuration: 25,
        shortBreakDuration: 5,
        longBreakDuration: 15,
        studyGoalMinutes: 120,
        legacyMigratedAt:
            await SupabaseAuthStorage.instance.readLegacyMigratedAt(user.id),
      );
      await _databaseService.client
          .from('user_settings')
          .insert(_toPayload(user: user, settings: created));
      return created;
    }

    UserSettingsModel settings = _fromStoredRow(
      user,
      Map<String, Object?>.from(result as Map),
      legacyMigratedAt: await SupabaseAuthStorage.instance.readLegacyMigratedAt(
        user.id,
      ),
    );

    final String syncedEmail = _preferredEmail(fallbackEmail, user.email);
    final String syncedName = _preferredDisplayName(
      fallbackDisplayName,
      user.userMetadata?['display_name']?.toString(),
    );
    final String? syncedStudentCode = _preferredStudentCode(
      fallbackStudentCode,
      user.userMetadata?['student_code']?.toString(),
    );

    if (settings.email != syncedEmail ||
        settings.displayName != syncedName ||
        settings.studentCode != syncedStudentCode ||
        (localOnboardingDone && !settings.onboardingDone)) {
      settings = settings.copyWith(
        email: syncedEmail,
        displayName: syncedName,
        studentCode: syncedStudentCode,
        onboardingDone: localOnboardingDone ? true : settings.onboardingDone,
      );
      await _databaseService.client
          .from('user_settings')
          .update(_toPayload(user: user, settings: settings))
          .eq('id', rowId);
    }

    return settings;
  }

  UserSettingsModel _fromStoredRow(
    User user,
    Map<String, Object?> row, {
    required DateTime? legacyMigratedAt,
  }) {
    final UserSettingsModel stored = UserSettingsModel.fromMap(
      <String, Object?>{
        ...row,
        'id': user.id,
      },
    );
    return stored.copyWith(
      userId: user.id,
      email: _preferredEmail(stored.email, user.email),
      studentCode: _preferredStudentCode(
        stored.studentCode,
        user.userMetadata?['student_code']?.toString(),
      ),
      joinedAt: DateTimeUtils.tryParse(user.createdAt),
      legacyMigratedAt: legacyMigratedAt,
    );
  }

  Map<String, Object?> _toPayload({
    required User user,
    required UserSettingsModel settings,
  }) {
    return <String, Object?>{
      'id': UserScope.profileRowId(user.id),
      'display_name': settings.displayName.trim(),
      'email': _preferredEmail(settings.email, user.email),
      'avatar': settings.avatar,
      'dark_mode': settings.darkMode,
      'notifications_enabled': settings.notificationsEnabled,
      'onboarding_done': settings.onboardingDone,
      'local_password': null,
      'is_logged_in': false,
      'focus_duration': settings.focusDuration,
      'short_break_duration': settings.shortBreakDuration,
      'long_break_duration': settings.longBreakDuration,
      'study_goal_minutes': settings.studyGoalMinutes,
    };
  }

  UserSettingsModel _guestSettings({bool? onboardingDone}) {
    return UserSettingsModel(
      userId: null,
      displayName: 'Student',
      email: '',
      avatar: null,
      studentCode: null,
      joinedAt: null,
      darkMode: false,
      notificationsEnabled: true,
      onboardingDone: onboardingDone ?? false,
      focusDuration: 25,
      shortBreakDuration: 5,
      longBreakDuration: 15,
      studyGoalMinutes: 120,
      legacyMigratedAt: null,
    );
  }

  User _requireCurrentUser() {
    final User? user = _databaseService.client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Ban can dang nhap de tiep tuc.');
    }
    return user;
  }

  String _mapAuthError(AuthException error) {
    final String message = error.message.trim();
    final String lower = message.toLowerCase();

    if (lower.contains('invalid login credentials')) {
      return 'Email hoặc mật khẩu chưa đúng.';
    }
    if (lower.contains('user already registered')) {
      return 'Email này đã được đăng ký.';
    }
    if (lower.contains('email rate limit exceeded')) {
      return 'Supabase đang gửi email xác minh thật và đã chạm giới hạn. Với môi trường phát triển, hãy tắt "Confirm email" trong Supabase Auth > Providers > Email.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Supabase vẫn đang yêu cầu xác minh email thật. Với môi trường phát triển, hãy tắt "Confirm email" trong Supabase Auth > Providers > Email.';
    }
    if (lower.contains('password should be at least')) {
      return 'Mật khẩu chưa đạt yêu cầu tối thiểu.';
    }
    if (message.isEmpty) {
      return 'Đã xảy ra lỗi xác thực với Supabase.';
    }
    return message;
  }

  String _preferredDisplayName(String? current, String? metadataValue) {
    final String currentValue = (current ?? '').trim();
    if (currentValue.isNotEmpty) {
      return currentValue;
    }
    final String metadata = (metadataValue ?? '').trim();
    if (metadata.isNotEmpty) {
      return metadata;
    }
    return 'Student';
  }

  String _preferredEmail(String? current, String? authEmail) {
    final String authValue = (authEmail ?? '').trim();
    if (authValue.isNotEmpty) {
      return authValue;
    }
    return (current ?? '').trim();
  }

  String? _preferredStudentCode(String? current, String? metadataValue) {
    final String currentValue = (current ?? '').trim();
    if (currentValue.isNotEmpty) {
      return currentValue;
    }
    final String metadata = (metadataValue ?? '').trim();
    if (metadata.isNotEmpty) {
      return metadata;
    }
    return null;
  }
}
