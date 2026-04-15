import 'dart:async';
import 'dart:convert';

import 'package:supabase/supabase.dart';

import '../auth/supabase_auth_storage.dart';
import '../config/app_env.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  bool _initialized = false;
  SupabaseClient? _client;
  // ignore: unused_field
  StreamSubscription<AuthState>? _authSubscription;

  SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw StateError('DatabaseService.init() must be called before client access.');
    }
    return _client!;
  }

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    await AppEnv.load();
    _client = SupabaseClient(
      AppEnv.supabaseUrl,
      AppEnv.supabasePublishableKey,
      authOptions: const AuthClientOptions(
        autoRefreshToken: true,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    await _restorePersistedSession();
    _authSubscription = _client!.auth.onAuthStateChange.listen((AuthState state) async {
      final Session? session = state.session;
      if (state.event == AuthChangeEvent.signedOut || session == null) {
        await SupabaseAuthStorage.instance.clearSession();
        return;
      }
      await SupabaseAuthStorage.instance.writeSession(jsonEncode(session.toJson()));
    });
    _initialized = true;
  }

  String? get currentUserId => _client?.auth.currentUser?.id;

  bool get isAuthenticated => currentUserId != null;

  String requireUserId() {
    final String? userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      throw const AuthException('Bạn cần đăng nhập để truy cập dữ liệu này.');
    }
    return userId;
  }

  Future<void> _restorePersistedSession() async {
    final String? serializedSession =
        await SupabaseAuthStorage.instance.readSession();
    if (serializedSession == null || serializedSession.trim().isEmpty) {
      return;
    }

    try {
      await _client!.auth.recoverSession(serializedSession);
    } catch (_) {
      await SupabaseAuthStorage.instance.clearSession();
    }
  }
}
