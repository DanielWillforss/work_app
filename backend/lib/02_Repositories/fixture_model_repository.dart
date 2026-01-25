import 'package:postgres/postgres.dart';
import 'package:shared_models/models/fixture_model.dart';
import 'package:workapp_backend/util/general_util.dart';

//Used for tests
typedef TxRunner =
    Future<T> Function<T>(Future<T> Function(Connection conn) fn);

class FixtureModelRepository {
  //used for tests
  final TxRunner? txRunner;
  FixtureModelRepository({this.txRunner});

  /// returns all FixtureModels as a list
  Future<List<Fixture>> findAll(Connection conn) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT * FROM fixtures.fixture_model
        ORDER BY model_name
      '''),
    );

    return result.map((row) => Fixture.fromSql(row.toColumnMap())).toList();
  }

  /// returns all FixtureTypes as a list
  Future<List<FixtureType>> findAllTypes(Connection conn) async {
    final result = await conn.execute(
      Sql.named('SELECT * FROM fixtures.fixture_type ORDER BY name'),
    );

    return result.map((row) => FixtureType.fromMap(row.toColumnMap())).toList();
  }

  /// returns all Manufacturers as a list
  Future<List<Manufacturer>> findAllManufacturers(Connection conn) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT * FROM fixtures.manufacturer
        ORDER BY name
      '''),
    );

    return result
        .map((row) => Manufacturer.fromMap(row.toColumnMap()))
        .toList();
  }

  /// returns fixture model by id
  /// throws IdNotFoundException for non-existant id
  Future<Fixture> findById(Connection conn, int id) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT * FROM fixtures.fixture_model
        WHERE id = @id
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) throw IdNotFoundException(id);
    return Fixture.fromSql(result.first.toColumnMap());
  }

  /// returns a list of fixture model with given type
  Future<List<Fixture>> findByType(Connection conn, int fixtureTypeId) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT * FROM fixtures.fixture_model
        WHERE fixture_type_id = @fixtureTypeId
        ORDER BY model_name
      '''),
      parameters: {'fixtureTypeId': fixtureTypeId},
    );

    if (result.isEmpty) throw IdNotFoundException(fixtureTypeId);
    return result.map((row) => Fixture.fromSql(row.toColumnMap())).toList();
  }

  /// returns a list of fixture model with given manufacturer
  Future<List<Fixture>> findByManufacturer(
    Connection conn,
    int manufacturerId,
  ) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT * FROM fixtures.fixture_model
        WHERE manufacturer_id = @manufacturerId
        ORDER BY model_name
      '''),
      parameters: {'manufacturerId': manufacturerId},
    );

    if (result.isEmpty) throw IdNotFoundException(manufacturerId);
    return result.map((row) => Fixture.fromSql(row.toColumnMap())).toList();
  }

  /// add new fixture model
  /// also creates new manufacturer if reference manufacturer doesn't exist
  /// Sets createdAt and updatedAt to now()
  Future<Fixture> insert(
    Connection conn, {
    required ManufacturerRef manufacturer,
    required int fixtureTypeId,
    required String modelName,
    String? shortName,
    double? powerPeakAmps,
    String? usualDmxMode,
    String? notes,
  }) async {
    final runner = txRunner ?? conn.runTx;
    final result = await runner((tx) async {
      final int resolvedManufacturerId;

      if (manufacturer is ManufacturerById) {
        resolvedManufacturerId = manufacturer.id;
      } else {
        // insert or get existing manufacturer
        final result = await tx.execute(
          Sql.named('''
            INSERT INTO fixtures.manufacturer (name)
            VALUES (@name)
            ON CONFLICT (name)
            DO UPDATE SET name = EXCLUDED.name
            RETURNING id
          '''),
          parameters: {'name': (manufacturer as ManufacturerByName).name},
        );
        resolvedManufacturerId = result.first[0] as int;
      }
      return await tx.execute(
        //This can most likely throw errors
        Sql.named('''
          INSERT INTO fixtures.fixture_model (
            manufacturer_id,
            fixture_type_id,
            model_name,
            short_name,
            power_peak_amps,
            usual_dmx_mode,
            notes
          ) VALUES (
            @manufacturerId,
            @fixtureTypeId,
            @modelName,
            @shortName,
            @powerPeakAmps,
            @usualDmxMode,
            @notes
          )
          RETURNING *
        '''),
        parameters: {
          'manufacturerId': resolvedManufacturerId,
          'fixtureTypeId': fixtureTypeId,
          'modelName': modelName,
          'shortName': shortName ?? '',
          'powerPeakAmps': powerPeakAmps,
          'usualDmxMode': usualDmxMode ?? '',
          'notes': notes ?? '',
        },
      );
    });
    return Fixture.fromSql(result.first.toColumnMap());
  }

  /// Update fixture model
  /// also creates new manufacturer if the new manufacturer doesn't exist
  /// removes old manufacturer if it's now unused by all models
  /// Sets updatedAt to now()
  /// throws IdNotFoundException if model Id does not exist
  /// throws IdNotFoundException if new manufacturer Id does not exist
  /// throws NullUpdateExeption if nothing is updated
  Future<Fixture> update(
    Connection conn, {
    required int id,
    ManufacturerRef? manufacturer,
    int? fixtureTypeId,
    String? modelName,
    String? shortName,
    double? powerPeakAmps,
    String? usualDmxMode,
    String? notes,
  }) async {
    final runner = txRunner ?? conn.runTx;
    return await runner((tx) async {
      final fields = <String>[];
      final parameters = <String, dynamic>{'id': id};

      int oldManufacturerId = -1;
      int newManufacturerId = -1;

      // First, get the current manufacturer_id for potential cleanup
      if (manufacturer != null) {
        final selectResult = await tx.execute(
          Sql.named(
            'SELECT manufacturer_id FROM fixtures.fixture_model WHERE id = @id FOR UPDATE',
          ),
          parameters: {'id': id},
        );

        oldManufacturerId = selectResult.first[0] as int;

        if (manufacturer is ManufacturerById) {
          newManufacturerId = manufacturer.id;
        } else {
          // Insert or get existing manufacturer
          final result = await tx.execute(
            Sql.named('''
            INSERT INTO fixtures.manufacturer (name)
            VALUES (@name)
            ON CONFLICT (name)
            DO UPDATE SET name = EXCLUDED.name
            RETURNING id
          '''),
            parameters: {'name': (manufacturer as ManufacturerByName).name},
          );
          newManufacturerId = result.first[0] as int;
        }

        fields.add('manufacturer_id = @manufacturerId');
        parameters['manufacturerId'] = newManufacturerId;
      }

      if (fixtureTypeId != null) {
        fields.add('fixture_type_id = @fixtureTypeId');
        parameters['fixtureTypeId'] = fixtureTypeId;
      }

      if (modelName != null) {
        fields.add('model_name = @modelName');
        parameters['modelName'] = modelName;
      }

      if (shortName != null) {
        fields.add('short_name = @shortName');
        parameters['shortName'] = shortName;
      }

      if (powerPeakAmps != null) {
        fields.add('power_peak_amps = @powerPeakAmps');
        parameters['powerPeakAmps'] = powerPeakAmps;
      }

      if (usualDmxMode != null) {
        fields.add('usual_dmx_mode = @usualDmxMode');
        parameters['usualDmxMode'] = usualDmxMode;
      }

      if (notes != null) {
        fields.add('notes = @notes');
        parameters['notes'] = notes;
      }

      if (fields.isEmpty) {
        throw NullUpdateException();
      }

      // Always update timestamp
      fields.add('updated_at = clock_timestamp()');

      final sql =
          '''
      UPDATE fixtures.fixture_model
      SET ${fields.join(', ')}
      WHERE id = @id
      RETURNING *
    ''';

      final result = await tx.execute(Sql.named(sql), parameters: parameters);

      if (result.isEmpty) {
        throw IdNotFoundException(id);
      }

      // Cleanup old manufacturer if it’s no longer used
      if (manufacturer != null && oldManufacturerId != newManufacturerId) {
        final countResult = await tx.execute(
          Sql.named(
            'SELECT COUNT(*) FROM fixtures.fixture_model WHERE manufacturer_id = @id',
          ),
          parameters: {'id': oldManufacturerId},
        );

        final count = countResult.first[0] as int;

        if (count == 0) {
          await tx.execute(
            Sql.named('DELETE FROM fixtures.manufacturer WHERE id = @id'),
            parameters: {'id': oldManufacturerId},
          );
        }
      }

      return Fixture.fromSql(result.first.toColumnMap());
    });
  }

  /// Delete fixture model
  /// also removes manufacturer if it's now unused by all models
  /// throws IdNotFoundException if model Id does not exist
  Future<void> delete(Connection conn, int id) async {
    final runner = txRunner ?? conn.runTx;
    await runner((ctx) async {
      // First, get the manufacturerId of the model being deleted
      final selectResult = await ctx.execute(
        Sql.named('''
        SELECT "manufacturer_id" FROM fixtures.fixture_model WHERE id = @id FOR UPDATE
      '''),
        parameters: {'id': id},
      );

      if (selectResult.affectedRows == 0) {
        throw IdNotFoundException(id);
      }

      final manufacturerId = selectResult.first[0] as int;

      // Delete the fixture model
      final deleteResult = await ctx.execute(
        Sql.named('''
          DELETE FROM fixtures.fixture_model
          WHERE id = @id
        '''),
        parameters: {'id': id},
      );

      if (deleteResult.affectedRows == 0) {
        throw IdNotFoundException(id);
      }

      // Check if any other models use the same manufacturer
      final countResult = await ctx.execute(
        Sql.named('''
          SELECT COUNT(*) FROM fixtures.fixture_model WHERE "manufacturer_id" = @manufacturer_id
        '''),
        parameters: {'manufacturer_id': manufacturerId},
      );

      final count = countResult.first[0] as int;

      if (count == 0) {
        // No other models use this manufacturer, safe to delete
        await ctx.execute(
          Sql.named('DELETE FROM fixtures.manufacturer WHERE id = @id'),
          parameters: {'id': manufacturerId},
        );
      }
    });
  }
}
