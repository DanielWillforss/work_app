import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';
import 'package:workapp_backend/01_routing/timelogs_routes.dart';
import 'package:workapp_backend/02_Repositories/timelog_repository.dart';

import '../test_util.dart';

void main() async {
  late Router router;
  late Connection conn;

  setUp(() async {
    conn = await TestDatabaseConnection.setUpTest();
    router = Router();
    TimelogRoutes(TimelogRepository(), conn).register(router);
  });

  tearDown(() async {
    await TestDatabaseConnection.tearDownTest(conn);
  });

  Future<Response> createTimelog({
    required DateTime startTime,
    DateTime? endTime,
    String? note,
  }) {
    return router.call(
      Request(
        'POST',
        Uri.parse('http://localhost/timelogs'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'start_time': startTime.toString(),
          if (endTime != null) 'end_time': endTime.toString(),
          if (note != null) 'note': note,
        }),
      ),
    );
  }

  group('GET /timelogs', () {
    test('returns empty list when database is empty', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/timelogs')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body, isList);
      expect(body, isEmpty);
    });

    test('returns all timelogs', () async {
      await createTimelog(startTime: DateTime.now(), note: 'Morning work');
      await createTimelog(
        startTime: DateTime.now().add(const Duration(hours: 1)),
        note: 'Afternoon work',
      );

      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/timelogs')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body.length, 2);
    });
  });

  group('POST /timelogs', () {
    test('creates a timelog', () async {
      final response = await createTimelog(
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        note: 'Worked on feature X',
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['status'], 'ok');
    });
  });

  group('GET /timelogs/<id>', () {
    test('returns timelog by id', () async {
      await createTimelog(startTime: DateTime.now(), note: 'Find me');

      final getAll = await router.call(
        Request('GET', Uri.parse('http://localhost/timelogs')),
      );
      final timelogs = jsonDecode(await getAll.readAsString());
      final id = timelogs.first['id'];

      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/timelogs/$id')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['id'], id);
    });

    test('returns bad request for invalid id', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/timelogs/abc')),
      );

      expect(response.statusCode, 400);
    });

    test('returns not_found for missing timelog', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/timelogs/9999')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['status'], 'not_found');
    });
  });

  group('PUT /timelogs/<id>', () {
    test('updates a timelog', () async {
      await createTimelog(startTime: DateTime.now(), note: 'Old note');

      final getAll = await router.call(
        Request('GET', Uri.parse('http://localhost/timelogs')),
      );
      final id = jsonDecode(await getAll.readAsString()).first['id'];

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/timelogs/$id'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'note': 'Updated note'}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['status'], 'updated');
    });

    test('fails for invalid id', () async {
      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/timelogs/abc'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'note': 'Update'}),
        ),
      );

      expect(response.statusCode, 400);
    });

    test('returns not_found when timelog does not exist', () async {
      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/timelogs/999'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'note': 'Update'}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'not_found');
    });
  });

  group('DELETE /timelogs/<id>', () {
    test('deletes a timelog', () async {
      await createTimelog(startTime: DateTime.now(), note: 'Delete me');

      final getAll = await router.call(
        Request('GET', Uri.parse('http://localhost/timelogs')),
      );
      final id = jsonDecode(await getAll.readAsString()).first['id'];

      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/timelogs/$id')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['status'], 'deleted');
    });

    test('fails for invalid id', () async {
      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/timelogs/abc')),
      );

      expect(response.statusCode, 400);
    });

    test('returns not_found for missing timelog', () async {
      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/timelogs/999')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'not_found');
    });
  });
}
