class DatabaseValueUtils {
  DatabaseValueUtils._();

  static int asInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static int? asNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value == 1;
    }
    if (value is num) {
      return value.toInt() == 1;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == '1' || normalized == 'true') {
        return true;
      }
      if (normalized == '0' || normalized == 'false') {
        return false;
      }
    }
    return fallback;
  }

  static String normalizeTimeString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final String raw = value.toString().trim();
    if (raw.isEmpty) {
      return fallback;
    }

    final List<String> parts = raw.split(':');
    if (parts.length < 2) {
      return raw;
    }

    final String hour = parts[0].padLeft(2, '0');
    final String minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }
}
