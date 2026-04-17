import 'package:flutter/material.dart';

import '../../../core/migration/legacy_sqlite_migration_service.dart';
import '../../profile/data/user_settings_model.dart';
import '../../profile/data/user_settings_repository.dart';

/// Controller quản lý phiên làm việc (session) và trạng thái người dùng toàn ứng dụng.
/// 
/// Sử dụng ChangeNotifier để các widget có thể lắng nghe và cập nhật UI khi trạng thái thay đổi.
/// Đây là lớp trung tâm quản lý: đăng nhập, đăng xuất, onboarding, và migrate dữ liệu cũ.
class AppSessionController extends ChangeNotifier {
  
  AppSessionController(
    this._settingsRepository,
    this._migrationService,
  );

  // Dependencies được inject từ bên ngoài (thường qua Provider hoặc GetIt)
  final UserSettingsRepository _settingsRepository;
  final LegacySqliteMigrationService _migrationService;

  // Trạng thái nội bộ
  UserSettingsModel? _settings;           // Thông tin người dùng hiện tại
  bool _isLoading = true;                 // Đang tải dữ liệu không?
  bool _localOnboardingDone = false;      // Onboarding đã hoàn thành ở local (dùng khi chưa có account)

  // Getter - cho phép các widget đọc trạng thái một cách an toàn
  UserSettingsModel? get settings => _settings;
  
  /// Đang trong quá trình tải dữ liệu (hydrate)
  bool get isLoading => _isLoading;

  /// Kiểm tra người dùng đã hoàn thành onboarding chưa
  /// (hoặc đã hoàn thành ở local hoặc trong database)
  bool get onboardingDone => _localOnboardingDone || (_settings?.onboardingDone ?? false);

  /// Kiểm tra người dùng đã đăng nhập chưa
  bool get isLoggedIn => _settings?.isAuthenticated ?? false;

  /// Tải toàn bộ dữ liệu phiên người dùng khi ứng dụng khởi động
  /// 
  /// Các bước thực hiện:
  /// 1. Đánh dấu đang loading
  /// 2. Lấy thông tin onboarding từ local
  /// 3. Lấy thông tin settings từ repository
  /// 4. Migrate dữ liệu cũ (nếu cần)
  /// 5. Hoàn tất và thông báo cho UI cập nhật
  Future<void> hydrate() async {
    _isLoading = true;
    notifyListeners();                    // Thông báo UI đang loading

    _localOnboardingDone = await _settingsRepository.getLocalOnboardingDone();
    _settings = await _settingsRepository.getSettings();
    
    await _migrateLegacyDataIfNeeded();   // Migrate dữ liệu từ SQLite cũ sang hệ thống mới

    _isLoading = false;
    notifyListeners();                    // Thông báo UI đã tải xong
  }

  /// Đánh dấu hoàn thành onboarding
  Future<void> completeOnboarding() async {
    _settings = await _settingsRepository.completeOnboarding();
    _localOnboardingDone = true;
    notifyListeners();
  }

  /// Đăng ký tài khoản mới
  Future<void> register({
    required String displayName,
    required String studentCode,
    required String email,
    required String password,
  }) async {
    _settings = await _settingsRepository.registerAccount(
      displayName: displayName,
      studentCode: studentCode,
      email: email,
      password: password,
    );
    _localOnboardingDone = true;
    await _migrateLegacyDataIfNeeded();
    notifyListeners();
  }

  /// Đăng nhập vào tài khoản
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _settings = await _settingsRepository.login(
      email: email,
      password: password,
    );
    await _migrateLegacyDataIfNeeded();
    notifyListeners();
  }

  /// Đăng xuất người dùng
  Future<void> logout() async {
    _settings = await _settingsRepository.logout();
    _localOnboardingDone = await _settingsRepository.getLocalOnboardingDone();
    notifyListeners();
  }

  /// Đặt lại mật khẩu
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    _settings = await _settingsRepository.resetPassword(
      email: email,
      newPassword: newPassword,
    );
    notifyListeners();
  }

  /// Yêu cầu gửi link/email đặt lại mật khẩu
  Future<void> requestPasswordReset({required String email}) async {
    await _settingsRepository.requestPasswordReset(email: email);
  }

  /// Làm mới thông tin settings (dùng sau khi có thay đổi ở nơi khác)
  Future<void> refreshSettings() async {
    _localOnboardingDone = await _settingsRepository.getLocalOnboardingDone();
    _settings = await _settingsRepository.getSettings();
    await _migrateLegacyDataIfNeeded();
    notifyListeners();
  }

  /// Hàm nội bộ: Migrate dữ liệu cũ từ SQLite legacy sang hệ thống mới
  /// Chỉ thực hiện khi người dùng đã đăng nhập
  Future<void> _migrateLegacyDataIfNeeded() async {
    final UserSettingsModel? current = _settings;
    
    // Nếu chưa có settings hoặc chưa đăng nhập thì bỏ qua
    if (current == null || !current.isAuthenticated) {
      return;
    }

    final LegacyMigrationSummary summary =
        await _migrationService.migrateForCurrentUser(current);

    // Nếu không có dữ liệu nào được import
    if (!summary.imported) {
      if (current.legacyMigratedAt == null) {
        _settings = await _settingsRepository.getSettings();
      }
      return;
    }

    // Nếu đã import thành công → lấy lại settings mới nhất
    _settings = await _settingsRepository.getSettings();
  }
}