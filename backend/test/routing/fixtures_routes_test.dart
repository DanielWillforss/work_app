import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

import 'package:workapp_backend/01_routing/fixtures_routes.dart';
import 'package:workapp_backend/02_Repositories/fixture_model_repository.dart';

import '../test_util.dart';

void main() {
  late Router router;
  late Connection conn;

  Future<T> testTx<T>(Future<T> Function(Connection conn) fn) async {
    return await fn(conn);
  }

  setUp(() async {
    conn = await TestDatabaseConnection.setUpTest();
    router = Router();

    FixturesRoutes(
      FixtureModelRepository(txRunner: testTx),
      conn,
    ).register(router);
  });

  tearDown(() async {
    await TestDatabaseConnection.tearDownTest(conn);
  });

  Future<Response> createModel({
    int? manufacturerId,
    String? manufacturerName,
    required int fixtureTypeId,
    required String modelName,
    Map<String, dynamic> extra = const {},
  }) {
    return router.call(
      Request(
        'POST',
        Uri.parse('http://localhost/fixtures/models'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'manufacturer_id': manufacturerId,
          'manufacturer_name': manufacturerName,
          'fixture_type_id': fixtureTypeId,
          'model_name': modelName,
          ...extra,
        }),
      ),
    );
  }

  group('GET /fixtures/types', () {
    test('returns initial fixture types', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/types')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body, isList);
      expect(body.length, 2);
      expect(body.first, contains('id'));
      expect(body.first, contains('name'));
    });
  });

  group('GET /fixtures/manufacturers', () {
    test('returns empty list initially', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/manufacturers')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body, isEmpty);
    });
  });

  group('GET /fixtures/models', () {
    test('returns empty list initially', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/models')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body, isEmpty);
    });
  });

  group('POST /fixtures/models', () {
    test('creates a model', () async {
      final response = await createModel(
        manufacturerName: "Test",
        fixtureTypeId: 1,
        modelName: 'MAC Aura',
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['model_name'], 'MAC Aura');
      expect(body['fixture_type_id'], 1);
    });

    test('fails when required fields are missing', () async {
      final response = await router.call(
        Request(
          'POST',
          Uri.parse('http://localhost/fixtures/models'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'model_name': 'Invalid'}),
        ),
      );

      expect(response.statusCode, 400);
    });

    test('fails for malformed payload', () async {
      final response = await router.call(
        Request(
          'POST',
          Uri.parse('http://localhost/fixtures/models'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'unexpected': 'key'}),
        ),
      );

      expect(response.statusCode, 400);
    });
  });

  group('GET /fixtures/models/<id>', () {
    test('returns model by id', () async {
      await createModel(
        manufacturerName: "Test",
        fixtureTypeId: 1,
        modelName: 'Sharpy',
      );

      final all = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/models')),
      );
      final id = jsonDecode(await all.readAsString()).first['id'];

      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/models/$id')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(response.statusCode, 200);
      expect(body['id'], id);
    });

    test('fails for invalid id', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/models/abc')),
      );

      expect(response.statusCode, 400);
    });

    test('returns not_found for missing model', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/models/999')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'not_found');
    });
  });

  group('GET /fixtures/models/type/<id>', () {
    test('returns models of a given type', () async {
      await createModel(
        manufacturerName: "Test",
        fixtureTypeId: 1,
        modelName: 'Type Match',
      );

      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/models/type/1')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body, isList);
      expect(body.length, 1);
    });

    test('returns not_found when no models exist for type', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/models/type/2')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'not_found');
    });

    test('fails for invalid id', () async {
      final response = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/models/type/abc')),
      );

      expect(response.statusCode, 400);
    });
  });

  group('GET /fixtures/models/manufacturer/<id>', () {
    test('returns not_found when none exist', () async {
      final response = await router.call(
        Request(
          'GET',
          Uri.parse('http://localhost/fixtures/models/manufacturer/999'),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'not_found');
    });
  });

  group('PUT /fixtures/models/<id>', () {
    test('updates a model', () async {
      await createModel(
        manufacturerName: "Test",
        fixtureTypeId: 1,
        modelName: 'Old Name',
      );

      final all = await router.call(
        Request('GET', Uri.parse('http://localhost/fixtures/models')),
      );
      final id = jsonDecode(await all.readAsString()).first['id'];

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/fixtures/models/$id'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'model_name': 'New Name'}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['model_name'], 'New Name');
    });

    test('returns null_update when no fields given', () async {
      await createModel(
        manufacturerName: "Test",
        fixtureTypeId: 1,
        modelName: 'No Update',
      );

      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/fixtures/models/1'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'null_update');
    });

    test('returns not_found when model does not exist', () async {
      final response = await router.call(
        Request(
          'PUT',
          Uri.parse('http://localhost/fixtures/models/999'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'model_name': 'Nope'}),
        ),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'not_found');
    });
  });

  group('DELETE /fixtures/models/<id>', () {
    test('fails for invalid id', () async {
      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/fixtures/models/abc')),
      );

      expect(response.statusCode, 400);
    });

    test('returns not_found for missing model', () async {
      final response = await router.call(
        Request('DELETE', Uri.parse('http://localhost/fixtures/models/999')),
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['status'], 'not_found');
    });
  });
}
