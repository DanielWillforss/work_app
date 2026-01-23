import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:workapp_backend/02_Repositories/fixture_model_repository.dart';
import 'package:workapp_backend/util/general_util.dart';

import '../test_util.dart';

Future<void> main() async {
  late Connection conn;
  late FixtureModelRepository repo;

  Future<T> testTx<T>(Future<T> Function(Connection conn) fn) async {
    // Just call the function directly with the same connection
    return await fn(conn);
  }

  setUp(() async {
    conn = await TestDatabaseConnection.setUpTest();
    repo = FixtureModelRepository(txRunner: testTx);
  });

  tearDown(() async {
    await TestDatabaseConnection.tearDownTest(conn);
  });

  const lightTypeId = 1;
  const speakerTypeId = 2;

  /// -------------------------
  /// findAll / lookup tables
  /// -------------------------

  test('findAllTypes returns seeded fixture types', () async {
    final types = await repo.findAllTypes(conn);

    expect(types.length, equals(2));
    final names = types.map((t) => t.name).toSet();
    expect(names, containsAll({'Light', 'Speaker'}));
  });

  test('findAllManufacturers returns empty list initially', () async {
    final manufacturers = await repo.findAllManufacturers(conn);

    expect(manufacturers, isEmpty);
  });

  test('findAll returns empty list when no models exist', () async {
    final models = await repo.findAll(conn);
    expect(models, isEmpty);
  });

  /// -------------------------
  /// insert
  /// -------------------------

  test('insert creates fixture model with new manufacturer by name', () async {
    final model = await repo.insert(
      conn,
      manufacturer: ManufacturerByName('ACME'),
      fixtureTypeId: lightTypeId,
      modelName: 'SuperBeam 3000',
    );

    expect(model.id, isA<int>());
    expect(model.modelName, equals('SuperBeam 3000'));
    expect(model.fixtureTypeId, equals(lightTypeId));
    expect(model.shortName, equals(''));
    expect(model.usualDmxMode, equals(''));
    expect(model.notes, equals(''));
    expect(model.powerPeakAmps, isNull);
    expect(model.createdAt, isA<DateTime>());
    expect(model.updatedAt, isA<DateTime>());

    final manufacturers = await repo.findAllManufacturers(conn);
    expect(manufacturers.length, equals(1));
    expect(manufacturers.single.name, equals('ACME'));
  });

  test(
    'insert reuses existing manufacturer when using ManufacturerById',
    () async {
      await repo.insert(
        conn,
        manufacturer: ManufacturerByName('ReuseCo'),
        fixtureTypeId: lightTypeId,
        modelName: 'Model A',
      );

      final manufacturers = await repo.findAllManufacturers(conn);
      expect(manufacturers.length, equals(1));

      await repo.insert(
        conn,
        manufacturer: ManufacturerById(manufacturers.single.id),
        fixtureTypeId: speakerTypeId,
        modelName: 'Model B',
      );

      final manufacturersAfter = await repo.findAllManufacturers(conn);
      expect(manufacturersAfter.length, equals(1));

      final models = await repo.findAll(conn);
      expect(models.length, equals(2));
    },
  );

  test('insert sets optional fields correctly', () async {
    final model = await repo.insert(
      conn,
      manufacturer: ManufacturerByName('OptiCorp'),
      fixtureTypeId: lightTypeId,
      modelName: 'Flex 200',
      shortName: 'F200',
      powerPeakAmps: 10,
      usualDmxMode: 'Mode 1',
      notes: 'Outdoor rated',
    );

    expect(model.shortName, equals('F200'));
    expect(model.powerPeakAmps, equals(10));
    expect(model.usualDmxMode, equals('Mode 1'));
    expect(model.notes, equals('Outdoor rated'));
  });

  /// -------------------------
  /// findById / filters
  /// -------------------------

  test('findById returns correct model', () async {
    final inserted = await repo.insert(
      conn,
      manufacturer: ManufacturerByName('Finder'),
      fixtureTypeId: lightTypeId,
      modelName: 'FindMe',
    );

    final fetched = await repo.findById(conn, inserted.id);
    expect(fetched.id, equals(inserted.id));
    expect(fetched.modelName, equals('FindMe'));
  });

  test('findById throws for non-existent id', () async {
    expect(
      () => repo.findById(conn, 9999),
      throwsA(isA<IdNotFoundException>()),
    );
  });

  test('findByType returns only matching fixture types', () async {
    await repo.insert(
      conn,
      manufacturer: ManufacturerByName('TypeCo'),
      fixtureTypeId: lightTypeId,
      modelName: 'Light A',
    );
    await repo.insert(
      conn,
      manufacturer: ManufacturerByName('TypeCo'),
      fixtureTypeId: speakerTypeId,
      modelName: 'Speaker A',
    );

    final lights = await repo.findByType(conn, lightTypeId);
    expect(lights.length, equals(1));
    expect(lights.single.modelName, equals('Light A'));
  });

  test('findByManufacturer returns only matching models', () async {
    final m1 = await repo.insert(
      conn,
      manufacturer: ManufacturerByName('BrandX'),
      fixtureTypeId: lightTypeId,
      modelName: 'X1',
    );

    await repo.insert(
      conn,
      manufacturer: ManufacturerByName('BrandY'),
      fixtureTypeId: lightTypeId,
      modelName: 'Y1',
    );

    final models = await repo.findByManufacturer(conn, m1.manufacturerId);
    expect(models.length, equals(1));
    expect(models.single.modelName, equals('X1'));
  });

  /// -------------------------
  /// update
  /// -------------------------

  test('update modifies model fields and updates timestamp', () async {
    final original = await repo.insert(
      conn,
      manufacturer: ManufacturerByName('UpCo'),
      fixtureTypeId: lightTypeId,
      modelName: 'OldName',
    );

    final updated = await repo.update(
      conn,
      id: original.id,
      modelName: 'NewName',
      notes: 'Updated notes',
    );

    expect(updated.modelName, equals('NewName'));
    expect(updated.notes, equals('Updated notes'));
    expect(updated.updatedAt.isAfter(original.updatedAt), isTrue);
  });

  test(
    'update changes manufacturer and removes unused old manufacturer',
    () async {
      final original = await repo.insert(
        conn,
        manufacturer: ManufacturerByName('OldBrand'),
        fixtureTypeId: lightTypeId,
        modelName: 'SwapMe',
      );

      await repo.update(
        conn,
        id: original.id,
        manufacturer: ManufacturerByName('NewBrand'),
      );

      final manufacturers = await repo.findAllManufacturers(conn);
      expect(manufacturers.length, equals(1));
      expect(manufacturers.single.name, equals('NewBrand'));
    },
  );

  test('update throws for non-existent model id', () async {
    expect(
      () => repo.update(conn, id: 9999, modelName: 'X'),
      throwsA(isA<IdNotFoundException>()),
    );
  });

  /// -------------------------
  /// delete
  /// -------------------------

  test('delete removes model and unused manufacturer', () async {
    final model = await repo.insert(
      conn,
      manufacturer: ManufacturerByName('TempBrand'),
      fixtureTypeId: lightTypeId,
      modelName: 'TempModel',
    );

    await repo.delete(conn, model.id);

    expect(
      () => repo.findById(conn, model.id),
      throwsA(isA<IdNotFoundException>()),
    );

    final manufacturers = await repo.findAllManufacturers(conn);
    expect(manufacturers, isEmpty);
  });

  test('delete does not remove manufacturer still in use', () async {
    final first = await repo.insert(
      conn,
      manufacturer: ManufacturerByName('SharedBrand'),
      fixtureTypeId: lightTypeId,
      modelName: 'A',
    );

    final second = await repo.insert(
      conn,
      manufacturer: ManufacturerById(first.manufacturerId),
      fixtureTypeId: speakerTypeId,
      modelName: 'B',
    );

    await repo.delete(conn, first.id);

    final manufacturers = await repo.findAllManufacturers(conn);
    expect(manufacturers.length, equals(1));

    final remaining = await repo.findAll(conn);
    expect(remaining.single.id, equals(second.id));
  });

  test('delete throws for non-existent model id', () async {
    expect(() => repo.delete(conn, 9999), throwsA(isA<IdNotFoundException>()));
  });
}
