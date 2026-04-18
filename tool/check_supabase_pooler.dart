import 'dart:io';

import 'package:postgres/postgres.dart';

Future<void> main() async {
  final Map<String, String> env = _readEnv(File('${Directory.current.path}/.env'));
  final String? databaseUrl = env['SUPABASE_DB_URL'];
  if (databaseUrl == null || databaseUrl.trim().isEmpty) {
    stderr.writeln('SUPABASE_DB_URL is missing from .env');
    exitCode = 1;
    return;
  }

  final _ParsedDatabaseUrl parsed = _parseDatabaseUrl(databaseUrl);
  for (final _ParsedDatabaseUrl candidate in _connectionCandidates(parsed)) {
    final PostgreSQLConnection connection = PostgreSQLConnection(
      candidate.host,
      candidate.port,
      candidate.databaseName,
      username: candidate.username,
      password: candidate.password,
      useSSL: candidate.useSsl,
      timeoutInSeconds: 10,
    );

    try {
      stdout.writeln(
        'TRY ${candidate.username}@${candidate.host}:${candidate.port}/${candidate.databaseName}',
      );
      await connection.open();
      stdout.writeln(
        'OPEN ${candidate.username}@${candidate.host}:${candidate.port}/${candidate.databaseName}',
      );
      await connection.close();
      return;
    } catch (error) {
      stdout.writeln(
        'FAIL ${candidate.username}@${candidate.host}:${candidate.port} => $error',
      );
    } finally {
      await connection.close();
    }
  }
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
  final String withoutScheme = raw.substring(prefix.length);
  final int slashIndex = withoutScheme.indexOf('/');
  final String authority = withoutScheme.substring(0, slashIndex);
  final String databaseAndQuery = withoutScheme.substring(slashIndex + 1);
  final int atIndex = authority.lastIndexOf('@');
  final String userInfo = authority.substring(0, atIndex);
  final String hostPort = authority.substring(atIndex + 1);
  final int colonIndex = userInfo.indexOf(':');
  final String username =
      colonIndex == -1 ? userInfo : userInfo.substring(0, colonIndex);
  final String? password =
      colonIndex == -1 ? null : userInfo.substring(colonIndex + 1);

  final int queryIndex = databaseAndQuery.indexOf('?');
  final String databaseName = queryIndex == -1
      ? databaseAndQuery
      : databaseAndQuery.substring(0, queryIndex);

  final int portSeparator = hostPort.lastIndexOf(':');
  final String host = portSeparator == -1
      ? hostPort
      : hostPort.substring(0, portSeparator);
  final int port =
      portSeparator == -1 ? 5432 : int.tryParse(hostPort.substring(portSeparator + 1)) ?? 5432;

  return _ParsedDatabaseUrl(
    host: host,
    port: port,
    databaseName: databaseName,
    username: Uri.decodeComponent(username),
    password: password == null ? null : Uri.decodeComponent(password),
    useSsl: true,
  );
}

Iterable<_ParsedDatabaseUrl> _connectionCandidates(_ParsedDatabaseUrl parsed) sync* {
  yield parsed;
  final String? password = parsed.password;
  if (password != null && password.startsWith('[') && password.endsWith(']')) {
    yield parsed.copyWith(password: password.substring(1, password.length - 1));
  }

  final RegExp match =
      RegExp(r'^db\.([a-z0-9]+)\.supabase\.co$', caseSensitive: false);
  final RegExpMatch? project = match.firstMatch(parsed.host);
  final String? projectRef = project?.group(1);
  if (projectRef == null) {
    return;
  }

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
    final String host = 'aws-0-$region.pooler.supabase.com';
    for (final String username in <String>[
      'postgres.$projectRef',
      'postgres',
    ]) {
      yield parsed.copyWith(
        host: host,
        port: 6543,
        username: username,
      );
      yield parsed.copyWith(
        host: host,
        port: 5432,
        username: username,
      );
    }
  }
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
