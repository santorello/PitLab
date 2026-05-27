import 'dart:convert';

List<String> parseDbStringList(dynamic value) {
  if (value == null) return const [];

  if (value is List) {
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const [];

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Non-JSON strings can still be plain text specs or Postgres arrays.
    }

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed
          .substring(1, trimmed.length - 1)
          .split(',')
          .map((item) => item.replaceAll('"', '').trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [trimmed];
  }

  return const [];
}
