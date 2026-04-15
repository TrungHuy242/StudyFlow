import 'package:flutter/material.dart';

import '../../../core/migration/legacy_sqlite_migration_service.dart';
import '../../profile/data/user_settings_model.dart';
import '../../profile/data/user_settings_repository.dart';

class AppSessionController extends ChangeNotifier {
  AppSessionController(
    this._settingsRepository,
    this._migrationService,
  );

  final UserSettingsRepository _settingsRepository;
  final LegacySqliteMigrationService _migrationService;

  UserSettingsModel? _settings;
  bool _isLoading = true;
  bool _localOnboardingDone = false;

  UserSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get onboardingDone => _localOnboardingDone || (_settings?.onboardingDone ?? false);
  bool get isLoggedIn => _settings?.isAuthenticated ?? false;

  Future<void> hydrate() async {
    _isLoading = true;
    notifyListeners();
    _localOnboardingDone = await _settingsRepository.getLocalOnboardingDone();
    _settings = await _settingsRepository.getSettings();
    await _migrateLegacyDataIfNeeded();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _settings = await _settingsRepository.completeOnboarding();
    _localOnboardingDone = true;
    notifyListeners();
  }

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

  Future<void> logout() async {
    _settings = await _settingsRepository.logout();
    _localOnboardingDone = await _settingsRepository.getLocalOnboardingDone();
    notifyListeners();
  }

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

  Future<void> requestPasswordReset({required String email}) async {
    await _settingsRepository.requestPasswordReset(email: email);
  }

  Future<void> refreshSettings() async {
    _localOnboardingDone = await _settingsRepository.getLocalOnboardingDone();
    _settings = await _settingsRepository.getSettings();
    await _migrateLegacyDataIfNeeded();
    notifyListeners();
  }

  Future<void> _migrateLegacyDataIfNeeded() async {
    final UserSettingsModel? current = _settings;
    if (current == null || !current.isAuthenticated) {
      return;
    }
    final LegacyMigrationSummary summary =
        await _migrationService.migrateForCurrentUser(current);
    if (!summary.imported) {
      if (current.legacyMigratedAt == null) {
        _settings = await _settingsRepository.getSettings();
      }
      return;
    }
    _settings = await _settingsRepository.getSettings();
  }
}
