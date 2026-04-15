import 'dart:math';

class UserScope {
  UserScope._();

  static const int _scopeSpan = 1000000000000;
  static const int _maxNamespace = 1000000;

  static int baseForUser(String userId) {
    final int namespace = _stableNamespace(userId);
    return namespace * _scopeSpan;
  }

  static int upperBoundForUser(String userId) {
    return baseForUser(userId) + _scopeSpan;
  }

  static int profileRowId(String userId) {
    return baseForUser(userId) + 1;
  }

  static int mapLegacyId(String userId, int legacyId) {
    return baseForUser(userId) + legacyId;
  }

  static int generateId(String userId) {
    final int base = baseForUser(userId);
    final int timestamp = DateTime.now().microsecondsSinceEpoch % _scopeSpan;
    final int random = Random().nextInt(1000);
    return base + ((timestamp + random) % _scopeSpan);
  }

  static int _stableNamespace(String userId) {
    int hash = 2166136261;
    for (final int codeUnit in userId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash % _maxNamespace;
  }
}
