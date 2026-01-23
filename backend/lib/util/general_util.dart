import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

Response jsonResponse(Object body) {
  return Response.ok(
    jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}

class IdNotFoundException implements Exception {
  final int id;

  IdNotFoundException(this.id);

  @override
  String toString() => 'Entry with id $id not found';
}

class NullUpdateException implements Exception {
  @override
  String toString() => 'Empty update not allowed';
}

sealed class ManufacturerRef {}

class ManufacturerById extends ManufacturerRef {
  final int id;
  ManufacturerById(this.id);
}

class ManufacturerByName extends ManufacturerRef {
  final String name;
  ManufacturerByName(this.name);
}

typedef TxRunner<T> =
    Future<T> Function(Connection conn, Future<T> Function(Connection conn) fn);

Future<T> noTx<T>(
  Connection conn,
  Future<T> Function(Connection conn) fn,
) async {
  return fn(conn);
}
