import 'dart:convert';

import 'package:shelf/shelf.dart';

class ParseResult<T> {
  final T? value;
  final Response? error;

  const ParseResult._(this.value, this.error);

  bool get isOk => error == null;

  static ParseResult<T> ok<T>(T value) => ParseResult._(value, null);

  static ParseResult<T> badRequest<T>(String message) =>
      ParseResult._(null, Response.badRequest(body: message));
}

/// returns string as int if possible
/// returns badRequest('Invalid id') otherwise
ParseResult<int> parseId(String rawId) {
  final parsed = int.tryParse(rawId);

  if (parsed == null) {
    return ParseResult.badRequest('Invalid id');
  }

  return ParseResult.ok(parsed);
}

/// returns null if the argument is null
/// returns string as DateTime if possible
/// returns badRequest('Invalid Datetime') otherwise
ParseResult<DateTime?> parseDatetime(String? rawDatetime) {
  if (rawDatetime == null) return ParseResult.ok(null);

  late final DateTime parsed;
  try {
    parsed = DateTime.parse(rawDatetime);
  } on FormatException {
    return ParseResult.badRequest('Invalid Datetime');
  }

  return ParseResult.ok(parsed);
}

ParseResult<double?> parseDouble(dynamic rawDouble) {
  // Case 1: It's already a double
  if (rawDouble == null) {
    return ParseResult.ok(null);
  }
  if (rawDouble is double) {
    return ParseResult.ok(rawDouble);
  }
  // Case 2: It's an int
  else if (rawDouble is int) {
    return ParseResult.ok(rawDouble.toDouble());
  }
  // Case 3: It's a string (optional, if JSON serialized numbers as strings)
  else if (rawDouble is String) {
    final output = double.tryParse(rawDouble);
    if (output == null) {
      return ParseResult.badRequest('Invalid Double');
    }
  }
  // Case 4: It's null or something else
  return ParseResult.badRequest('Invalid Double');
}

/// Returns the request as a map if possible
/// Returns null if not possible
/// Returns null if the request contains keys not mentioned in allowedKeys
Future<Map<String, dynamic>?> decodeRequest(
  Request req, {
  Set<String>? allowedKeys,
}) async {
  late final Map<String, dynamic> payload;
  try {
    final body = await req.readAsString();
    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    payload = decoded;
  } catch (_) {
    return null;
  }

  if (allowedKeys == null) {
    return payload;
  }

  //if allowed keys is used
  final unexpectedKeys = payload.keys.where((k) => !allowedKeys.contains(k));

  if (unexpectedKeys.isNotEmpty) {
    return null;
  }

  return payload;
}
