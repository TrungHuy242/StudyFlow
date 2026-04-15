import 'dart:io';

import 'package:supabase/supabase.dart';

Future<void> main() async {
  final Map<String, String> env = _readEnv(File('${Directory.current.path}/.env'));
  final String? supabaseUrl = env['SUPABASE_URL'];
  final String? publishableKey = env['SUPABASE_PUBLISHABLE_KEY'];
  if (supabaseUrl == null || supabaseUrl.trim().isEmpty) {
    stderr.writeln('SUPABASE_URL is missing from .env');
    exitCode = 1;
    return;
  }
  if (publishableKey == null || publishableKey.trim().isEmpty) {
    stderr.writeln('SUPABASE_PUBLISHABLE_KEY is missing from .env');
    exitCode = 1;
    return;
  }

  final SupabaseClient client = SupabaseClient(
    supabaseUrl,
    publishableKey,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  const List<String> tables = <String>[
    'semesters',
    'subjects',
    'schedules',
    'deadlines',
    'study_plans',
    'pomodoro_sessions',
    'notes',
    'notifications',
    'user_settings',
  ];

  for (final String table in tables) {
    final List<dynamic> rows =
        await client.from(table).select('id').limit(1) as List<dynamic>;
    stdout.writeln('$table\tOK\t${rows.length}');
  }

  await client.dispose();
}

Map<String, String> _readEnv(File envFile) {
  final Map<String, String> values = <String, String>{};
  if (!envFile.existsSync()) {
    return values;
  }

  for (final String rawLine in envFile.readAsLinesSync()) {
    final String line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final int separator = line.indexOf('=');
    if (separator <= 0) {
      continue;
    }
    final String key = line.substring(0, separator).trim();
    String value = line.substring(separator + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    values[key] = value;
  }
  return values;
}
