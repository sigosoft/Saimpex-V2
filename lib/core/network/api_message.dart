import 'dart:convert';

Map<String, dynamic>? asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String && value.trim().isNotEmpty) {
    try {
      return asJsonMap(jsonDecode(value));
    } catch (_) {
      return null;
    }
  }
  return null;
}

String resolveApiMessage(
  dynamic message,
  String language, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (message == null) return fallback;

  final direct = _readText(message);
  if (direct != null && message is! Map) return direct;

  if (message is Map) {
    final localized = <String>[];
    for (final entry in message.entries) {
      if (entry.key.toString().endsWith('_$language')) {
        final text = _readText(entry.value);
        if (text != null) localized.add(text);
      }
    }
    if (localized.isNotEmpty) return localized.join('\n');

    // Validation-style errors nest the languages under a field name, e.g.
    // {"is_self_pickup": {"message_en": [...]}} on a 422.
    for (final entry in message.entries) {
      if (entry.value is Map) {
        final nested = resolveApiMessage(entry.value, language, fallback: '');
        if (nested.isNotEmpty) return nested;
      }
    }

    for (final entry in message.entries) {
      final text = _readText(entry.value);
      if (text != null) return text;
    }
  }

  return direct ?? fallback;
}

String? _readText(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is List) {
    final parts = value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }
  return null;
}

class ApiEnvelope {
  const ApiEnvelope({
    required this.statusCode,
    required this.data,
    required this.message,
  });

  final int? statusCode;
  final dynamic data;
  final String message;

  factory ApiEnvelope.parse(dynamic body, String language, {int? statusCode}) {
    final map = asJsonMap(body);
    if (map == null) {
      throw const FormatException('Unexpected server response');
    }

    final success = map['status'] == true;
    final message = resolveApiMessage(
      map['message'],
      language,
      fallback: success ? 'Success' : 'Request failed. Please try again.',
    );

    if (!success) {
      throw FormatException(message);
    }

    return ApiEnvelope(
      statusCode: statusCode,
      data: map['data'],
      message: message,
    );
  }
}
