import '../../../core/database/database_service.dart';
import 'user_settings_model.dart';

class UserSettingsRepository {
  UserSettingsRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<UserSettingsModel> getSettings() async {
    final database = await _databaseService.database;
    final List<Map<String, Object?>> result = await database.query(
      'user_settings',
      limit: 1,
    );
    return UserSettingsModel.fromMap(result.first);
  }

  Future<UserSettingsModel> saveSettings(UserSettingsModel settings) async {
    final database = await _databaseService.database;
    await database.update(
      'user_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[settings.id],
    );
    return getSettings();
  }

  Future<UserSettingsModel> completeOnboarding() async {
    final UserSettingsModel current = await getSettings();
    return saveSettings(current.copyWith(onboardingDone: true));
  }

  Future<UserSettingsModel> registerLocalAccount({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final UserSettingsModel current = await getSettings();
    return saveSettings(
      current.copyWith(
        displayName: displayName,
        email: email,
        localPassword: password,
        onboardingDone: true,
        isLoggedIn: true,
      ),
    );
  }

  Future<UserSettingsModel> login({
    required String email,
    required String password,
  }) async {
    final UserSettingsModel current = await getSettings();
    if (current.email.trim().toLowerCase() != email.trim().toLowerCase() ||
        current.localPassword != password) {
      throw const FormatException('Email or password is incorrect.');
    }
    return saveSettings(current.copyWith(isLoggedIn: true));
  }

  Future<UserSettingsModel> logout() async {
    final UserSettingsModel current = await getSettings();
    return saveSettings(current.copyWith(isLoggedIn: false));
  }

  Future<UserSettingsModel> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final UserSettingsModel current = await getSettings();
    if (current.email.trim().toLowerCase() != email.trim().toLowerCase()) {
      throw const FormatException('Email không tồn tại trong thiết bị này.');
    }
    return saveSettings(
      current.copyWith(
        localPassword: newPassword,
        isLoggedIn: false,
      ),
    );
  }
}
