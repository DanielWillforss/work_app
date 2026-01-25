import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_models/models/fixture_model.dart';
import 'package:work_app/main.dart';

class FixturesApi {
  static const String baseUrl = GlobalConstants.baseUrl;

  /// GET /fixtures/models
  static Future<List<Fixture>> getFixtures() async {
    final response = await http.get(Uri.parse('$baseUrl/fixtures/models'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load fixtures');
    }

    //print(response.body);

    final List data = jsonDecode(response.body);
    return data.map((e) => Fixture.fromMap(e)).toList();
  }

  /// GET /fixtures/models/{id}
  static Future<Fixture> getFixture(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/fixtures/models/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load fixture');
    }

    return Fixture.fromMap(jsonDecode(response.body));
  }

  /// GET /fixtures/models/type/{id}
  static Future<List<Fixture>> getFixturesByType(int typeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fixtures/models/type/$typeId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load fixtures by type');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => Fixture.fromMap(e)).toList();
  }

  /// GET /fixtures/models/manufacturer/{id}
  static Future<List<Fixture>> getFixturesByManufacturer(
    int manufacturerId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fixtures/models/manufacturer/$manufacturerId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load fixtures by manufacturer');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => Fixture.fromMap(e)).toList();
  }

  /// POST /fixtures/models
  static Future<Fixture> createFixture({
    int? manufacturerId,
    String? manufacturerName,
    required int fixtureTypeId,
    required String modelName,
    String shortName = '',
    double? powerPeakAmps,
    String usualDmxMode = '',
    String notes = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fixtures/models'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'manufacturer_id': manufacturerId,
        'manufacturer_name': manufacturerName,
        'fixture_type_id': fixtureTypeId,
        'model_name': modelName,
        'short_name': shortName,
        'power_peak_amps': powerPeakAmps,
        'usual_dmx_mode': usualDmxMode,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create fixture');
    }

    return Fixture.fromMap(jsonDecode(response.body));
  }

  /// PUT /fixtures/models/{id}
  static Future<Fixture> updateFixture(
    int id, {
    int? manufacturerId,
    String? manufacturerName,
    required int fixtureTypeId,
    required String modelName,
    String shortName = '',
    double? powerPeakAmps,
    String usualDmxMode = '',
    String notes = '',
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/fixtures/models/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'manufacturer_id': manufacturerId,
        'manufacturer_name': manufacturerName,
        'fixture_type_id': fixtureTypeId,
        'model_name': modelName,
        'short_name': shortName,
        'power_peak_amps': powerPeakAmps,
        'usual_dmx_mode': usualDmxMode,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update fixture');
    }

    return Fixture.fromMap(jsonDecode(response.body));
  }

  /// DELETE /fixtures/models/{id}
  static Future<void> deleteFixture(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/fixtures/models/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete fixture');
    }
  }

  /// GET /fixtures/manufacturers
  static Future<List<Manufacturer>> getManufacturers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/fixtures/manufacturers'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load manufacturers');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => Manufacturer.fromMap(e)).toList();
  }

  /// GET /fixtures/types
  static Future<List<FixtureType>> getFixtureTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/fixtures/types'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load fixture types');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => FixtureType.fromMap(e)).toList();
  }
}
