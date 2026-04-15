import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

Future<void> main(List<String> args) async {
  final String projectRoot = Directory.current.path;
  final File envFile = File('$projectRoot/.env');
  final Directory migrationsDirectory =
      Directory('$projectRoot/supabase/migrations');

  if (!envFile.existsSync()) {
    stderr.writeln('.env not found at ${envFile.path}');
    exitCode = 1;
    return;
  }
  if (!migrationsDirectory.existsSync()) {
    stderr.writeln('Migration directory not found at ${migrationsDirectory.path}');
    exitCode = 1;
    return;
  }

  final Map<String, String> env = _readEnv(envFile);
  final String? databaseUrl = env['SUPABASE_DB_URL'];
  if (databaseUrl == null || databaseUrl.trim().isEmpty) {
    stderr.writeln('SUPABASE_DB_URL is missing from .env');
    exitCode = 1;
    return;
  }

  final _ParsedDatabaseUrl parsed = _parseDatabaseUrl(databaseUrl);
  final List<File> migrationFiles = migrationsDirectory
      .listSync()
      .whereType<File>()
      .where((File file) => file.path.toLowerCase().endsWith('.sql'))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));

  if (migrationFiles.isEmpty) {
    stderr.writeln('No SQL migrations found at ${migrationsDirectory.path}');
    exitCode = 1;
    return;
  }

  final List<String> statements = <String>[];
  for (final File migrationFile in migrationFiles) {
    final String sql = migrationFile.readAsStringSync();
    statements.addAll(_splitSqlStatements(sql));
  }

  Object? lastError;
  for (final _ParsedDatabaseUrl candidate in _connectionCandidates(parsed)) {
    for (int attempt = 1; attempt <= 4; attempt++) {
      final PostgreSQLConnection connection = PostgreSQLConnection(
        candidate.host,
        candidate.port,
        candidate.databaseName,
        username: candidate.username,
        password: candidate.password,
        useSSL: candidate.useSsl,
        timeoutInSeconds: 30,
      );

      try {
        stdout.writeln('Connecting to Supabase Postgres (attempt $attempt)...');
        await connection.open();
        for (final String statement in statements) {
          if (statement.trim().isEmpty) {
            continue;
          }
          await connection.execute(statement);
        }
        stdout.writeln(
          'Applied ${statements.where((String s) => s.trim().isNotEmpty).length} SQL statements successfully.',
        );
        return;
      } catch (error) {
        lastError = error;
        if (attempt < 4) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      } finally {
        await connection.close();
      }
    }
  }

  stderr.writeln('Unable to apply Supabase schema: $lastError');
  exitCode = 1;
}

Map<String, String> _readEnv(File envFile) {
  final Map<String, String> values = <String, String>{};
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

_ParsedDatabaseUrl _parseDatabaseUrl(String raw) {
  const String prefix = 'postgresql://';
  if (!raw.startsWith(prefix)) {
    throw const FormatException('Unsupported database URL format.');
  }

  final String withoutScheme = raw.substring(prefix.length);
  final int slashIndex = withoutScheme.indexOf('/');
  if (slashIndex == -1) {
    throw const FormatException('Database URL is missing the database name.');
  }

  final String authority = withoutScheme.substring(0, slashIndex);
  final String databaseAndQuery = withoutScheme.substring(slashIndex + 1);
  final int atIndex = authority.lastIndexOf('@');
  if (atIndex == -1) {
    throw const FormatException('Database URL is missing credentials or host.');
  }

  final String userInfo = authority.substring(0, atIndex);
  final String hostPort = authority.substring(atIndex + 1);
  final int colonIndex = userInfo.indexOf(':');
  final String username = colonIndex == -1
      ? userInfo
      : userInfo.substring(0, colonIndex);
  final String? password =
      colonIndex == -1 ? null : userInfo.substring(colonIndex + 1);

  final int queryIndex = databaseAndQuery.indexOf('?');
  final String databaseName = queryIndex == -1
      ? databaseAndQuery
      : databaseAndQuery.substring(0, queryIndex);
  final String query = queryIndex == -1 ? '' : databaseAndQuery.substring(queryIndex + 1);

  final int portSeparator = hostPort.lastIndexOf(':');
  final String host;
  final int port;
  if (portSeparator == -1) {
    host = hostPort;
    port = 5432;
  } else {
    host = hostPort.substring(0, portSeparator);
    port = int.tryParse(hostPort.substring(portSeparator + 1)) ?? 5432;
  }

  final Map<String, String> queryParameters = Uri.splitQueryString(
    query,
    encoding: utf8,
  );

  return _ParsedDatabaseUrl(
    host: host,
    port: port,
    databaseName: databaseName,
    username: Uri.decodeComponent(username),
    password: password == null ? null : Uri.decodeComponent(password),
    useSsl: (queryParameters['sslmode'] ?? 'require').toLowerCase() != 'disable',
  );
}

Iterable<_ParsedDatabaseUrl> _connectionCandidates(_ParsedDatabaseUrl parsed) sync* {
  yield parsed;
  final String? password = parsed.password;
  if (password != null && password.startsWith('[') && password.endsWith(']')) {
    yield parsed.copyWith(password: password.substring(1, password.length - 1));
  }

  final String? projectRef = _extractProjectRef(parsed.host);
  if (projectRef != null) {
    const List<String> regions = <String>[
      'ap-southeast-1',
      'ap-southeast-2',
      'ap-south-1',
      'ap-northeast-1',
      'ap-northeast-2',
      'eu-west-1',
      'eu-west-2',
      'eu-central-1',
      'us-west-1',
      'us-west-2',
      'us-east-1',
      'ca-central-1',
      'sa-east-1',
    ];
    for (final String region in regions) {
      final String poolerHost = 'aws-0-$region.pooler.supabase.com';
      yield parsed.copyWith(
        host: poolerHost,
        port: 6543,
        username: 'postgres.$projectRef',
      );
      yield parsed.copyWith(
        host: poolerHost,
        port: 5432,
        username: 'postgres.$projectRef',
      );
    }
  }
}

String? _extractProjectRef(String host) {
  final RegExp match = RegExp(r'^db\.([a-z0-9]+)\.supabase\.co$', caseSensitive: false);
  final RegExpMatch? result = match.firstMatch(host);
  return result?.group(1);
}

List<String> _splitSqlStatements(String sql) {
  final List<String> statements = <String>[];
  final StringBuffer current = StringBuffer();

  bool inSingleQuote = false;
  bool inDoubleQuote = false;
  bool inLineComment = false;
  bool inBlockComment = false;
  String? dollarQuote;

  for (int index = 0; index < sql.length; index++) {
    final String char = sql[index];
    final String next = index + 1 < sql.length ? sql[index + 1] : '';

    if (inLineComment) {
      current.write(char);
      if (char == '\n') {
        inLineComment = false;
      }
      continue;
    }

    if (inBlockComment) {
      current.write(char);
      if (char == '*' && next == '/') {
        current.write(next);
        index++;
        inBlockComment = false;
      }
      continue;
    }

    if (!inSingleQuote && !inDoubleQuote && dollarQuote == null) {
      if (char == '-' && next == '-') {
        current.write(char);
        current.write(next);
        index++;
        inLineComment = true;
        continue;
      }
      if (char == '/' && next == '*') {
        current.write(char);
        current.write(next);
        index++;
        inBlockComment = true;
        continue;
      }

      if (char == r'$') {
        final int end = sql.indexOf(r'$', index + 1);
        if (end != -1) {
          final String tag = sql.substring(index, end + 1);
          if (RegExp(r'^\$[A-Za-z0-9_]*\$$').hasMatch(tag)) {
            dollarQuote = tag;
            current.write(tag);
            index = end;
            continue;
          }
        }
      }
    } else if (dollarQuote != null) {
      if (sql.startsWith(dollarQuote, index)) {
        current.write(dollarQuote);
        index += dollarQuote.length - 1;
        dollarQuote = null;
        continue;
      }
      current.write(char);
      continue;
    }

    if (char == "'" && !inDoubleQuote) {
      final bool escaped = index > 0 && sql[index - 1] == r'\';
      if (!escaped) {
        inSingleQuote = !inSingleQuote;
      }
      current.write(char);
      continue;
    }

    if (char == '"' && !inSingleQuote) {
      final bool escaped = index > 0 && sql[index - 1] == r'\';
      if (!escaped) {
        inDoubleQuote = !inDoubleQuote;
      }
      current.write(char);
      continue;
    }

    if (char == ';' && !inSingleQuote && !inDoubleQuote && dollarQuote == null) {
      final String statement = current.toString().trim();
      if (statement.isNotEmpty) {
        statements.add(statement);
      }
      current.clear();
      continue;
    }

    current.write(char);
  }

  final String tail = current.toString().trim();
  if (tail.isNotEmpty) {
    statements.add(tail);
  }

  return statements;
}

class _ParsedDatabaseUrl {
  const _ParsedDatabaseUrl({
    required this.host,
    required this.port,
    required this.databaseName,
    required this.username,
    required this.password,
    required this.useSsl,
  });

  final String host;
  final int port;
  final String databaseName;
  final String username;
  final String? password;
  final bool useSsl;

  _ParsedDatabaseUrl copyWith({
    String? host,
    int? port,
    String? databaseName,
    String? username,
    String? password,
    bool? useSsl,
  }) {
    return _ParsedDatabaseUrl(
      host: host ?? this.host,
      port: port ?? this.port,
      databaseName: databaseName ?? this.databaseName,
      username: username ?? this.username,
      password: password ?? this.password,
      useSsl: useSsl ?? this.useSsl,
    );
  }
}
