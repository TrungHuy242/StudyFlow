import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) {
      return;
    }
    await dotenv.load(fileName: '.env');
    _loaded = true;
  }

  static String get supabaseUrl => _required('SUPABASE_URL');

  static String get supabasePublishableKey => _required('SUPABASE_PUBLISHABLE_KEY');

  static String? get supabaseDbUrl => dotenv.maybeGet('SUPABASE_DB_URL');

  static String get geminiApiKey => _required('GEMINI_API_KEY');

  static String get geminiModel {
    final String? value = dotenv.maybeGet('GEMINI_MODEL');
    if (value == null || value.trim().isEmpty) {
      return 'gemini-2.5-flash';
    }
    return value.trim();
  }

  static String _required(String key) {
    final String? value = dotenv.maybeGet(key);
    if (value == null || value.trim().isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }
    return value;
  }
}
