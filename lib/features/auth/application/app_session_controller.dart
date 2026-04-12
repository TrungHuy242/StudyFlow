import 'package:flutter/material.dart';

import '../../profile/data/user_settings_model.dart';
import '../../profile/data/user_settings_repository.dart';

class AppSessionController extends ChangeNotifier {
  AppSessionController(this._settingsRepository);

  final UserSettingsRepository _settingsRepository;

  UserSettingsModel? _settings;
  bool _isLoading = true;

  UserSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get onboardingDone => _settings?.onboardingDone ?? false;
  bool get isLoggedIn => _settings?.isLoggedIn ?? false;
  bool get hasLocalAccount => _settings?.hasLocalAccount ?? false;

  Future<void> hydrate() async {
    _isLoading = true;
    notifyListeners();
    _settings = await _settingsRepository.getSettings();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _settings = await _settingsRepository.completeOnboarding();
    notifyListeners();
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _settings = await _settingsRepository.registerLocalAccount(
      displayName: displayName,
      email: email,
      password: password,
    );
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
    notifyListeners();
  }

  Future<void> logout() async {
    _settings = await _settingsRepository.logout();
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

  Future<void> refreshSettings() async {
    _settings = await _settingsRepository.getSettings();
    notifyListeners();
  }
}
