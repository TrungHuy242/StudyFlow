import 'package:shared_preferences/shared_preferences.dart';

class SupabaseAuthStorage {
  SupabaseAuthStorage._();

  static final SupabaseAuthStorage instance = SupabaseAuthStorage._();

  static const String _sessionKey = 'studyflow.supabase.session';
  static const String _onboardingKey = 'studyflow.onboarding.done';
  static const String _legacyPrefix = 'studyflow.legacy.migrated.';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> readSession() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(_sessionKey);
  }

  Future<void> writeSession(String value) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_sessionKey, value);
  }

  Future<void> clearSession() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(_sessionKey);
  }

  Future<bool> readOnboardingDone() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> writeOnboardingDone(bool value) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setBool(_onboardingKey, value);
  }

  Future<DateTime?> readLegacyMigratedAt(String userId) async {
    final SharedPreferences prefs = await _prefs;
    final String? value = prefs.getString('$_legacyPrefix$userId');
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  Future<void> writeLegacyMigratedAt(String userId, DateTime value) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(
      '$_legacyPrefix$userId',
      value.toUtc().toIso8601String(),
    );
  }
}
