/// Robust JSON type-safe parser for Laravel 13 + PostgreSQL 18 serialized types.
/// Prevents runtime TypeErrors when decimal numbers are returned as String,
/// timestamps as ISO-8601 strings, or booleans as integers.
class SafeJsonParser {
  SafeJsonParser._();

  /// Parse double safely from String ("431000.00"), int, double, or null.
  static double toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) {
      return defaultValue;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      final clean = value.trim();
      if (clean.isEmpty) return defaultValue;
      return double.tryParse(clean) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Parse int safely from int, double, String ("12"), or null.
  static int toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) {
      return defaultValue;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      final clean = value.trim();
      if (clean.isEmpty) return defaultValue;
      final parsedInt = int.tryParse(clean);
      if (parsedInt != null) return parsedInt;
      final parsedDouble = double.tryParse(clean);
      if (parsedDouble != null) return parsedDouble.toInt();
      return defaultValue;
    }
    return defaultValue;
  }

  /// Parse nullable int safely from int, double, String, or null.
  static int? toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final clean = value.trim();
      if (clean.isEmpty) return null;
      return int.tryParse(clean) ?? double.tryParse(clean)?.toInt();
    }
    return null;
  }

  /// Parse nullable double safely from double, int, String, or null.
  static double? toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final clean = value.trim();
      if (clean.isEmpty) return null;
      return double.tryParse(clean);
    }
    return null;
  }

  /// Parse non-null string safely.
  static String toStringValue(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString().trim();
  }

  /// Parse nullable string safely.
  static String? toNullableString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  /// Parse bool safely from bool, int (1/0), String ("true"/"1"), or null.
  static bool toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) {
      return defaultValue;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 't' || lower == 'yes') {
        return true;
      }
      if (lower == 'false' || lower == '0' || lower == 'f' || lower == 'no') {
        return false;
      }
    }
    return defaultValue;
  }

  /// Parse DateTime safely from ISO-8601 String ("2026-11-14T18:25:26+07:00") or DateTime.
  static DateTime? toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toLocal();
    }
    if (value is String) {
      final clean = value.trim();
      if (clean.isEmpty) return null;
      return DateTime.tryParse(clean)?.toLocal();
    }
    return null;
  }

  /// Alias for toDateTime
  static DateTime? toNullableDateTime(dynamic value) => toDateTime(value);
}
