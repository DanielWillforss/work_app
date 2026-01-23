import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:workapp_backend/02_Repositories/timelog_repository.dart';
import 'package:workapp_backend/util/general_util.dart';

import '../test_util.dart';

Future<void> main() async {
  late Connection conn;
  TimelogRepository timelogRepo = TimelogRepository();

  setUp(() async {
    conn = await TestDatabaseConnection.setUpTest();
  });

  tearDown(() async {
    await TestDatabaseConnection.tearDownTest(conn);
  });

  // Test: insert and retrieve a timelog
  test('insert and retrieve a timelog', () async {
    final startTime = DateTime.now();
    final endTime = startTime.add(const Duration(hours: 1));
    const note = 'Worked on project X';

    await timelogRepo.insert(
      conn,
      startTime: startTime,
      endTime: endTime,
      note: note,
    );

    final timelogs = await timelogRepo.findAll(conn);
    expect(timelogs, isNotEmpty);

    final timelog = timelogs.single;
    expect(timelog.startTime.toUtc(), equals(startTime.toUtc()));
    expect(timelog.endTime?.toUtc(), equals(endTime.toUtc()));
    expect(timelog.note, equals(note));
    expect(timelog.id, isA<int>());
  });

  // Test: findAll returns all timelogs
  test('findAll returns all timelogs', () async {
    final now = DateTime.now();
    await timelogRepo.insert(
      conn,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      note: 'TL1',
    );
    await timelogRepo.insert(
      conn,
      startTime: now,
      endTime: now.add(const Duration(hours: 2)),
      note: 'TL2',
    );

    final timelogs = await timelogRepo.findAll(conn);
    final sorted = timelogs..sort((a, b) => a.id.compareTo(b.id));
    expect(timelogs.length, equals(2));
    expect(sorted[0].note, equals('TL1'));
    expect(sorted[1].note, equals('TL2'));
  });

  // Test: findById returns correct timelog
  test('findById returns timelog by id', () async {
    final now = DateTime.now();
    await timelogRepo.insert(
      conn,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      note: 'Single TL',
    );
    final timelog = (await timelogRepo.findAll(conn)).single;

    final fetched = await timelogRepo.findById(conn, timelog.id);
    expect(fetched, isNotNull);
    expect(fetched.id, equals(timelog.id));
    expect(fetched.note, equals('Single TL'));
  });

  // Test: findById throws for non-existent id
  test('findById throws exception for non-existent id', () async {
    expect(
      () => timelogRepo.findById(conn, 9999),
      throwsA(isA<IdNotFoundException>()),
    );
  });

  // Test: update timelog successfully
  test('update modifies existing timelog', () async {
    final now = DateTime.now();
    await timelogRepo.insert(
      conn,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      note: 'Old note',
    );
    final timelog = (await timelogRepo.findAll(conn)).single;

    final newStart = now.add(const Duration(hours: 2));
    final newEnd = now.add(const Duration(hours: 3));

    await timelogRepo.update(
      conn,
      id: timelog.id,
      startTime: newStart,
      endTime: newEnd,
      note: 'Updated note',
    );

    final updated = await timelogRepo.findById(conn, timelog.id);
    expect(updated, isNotNull);
    expect(updated.startTime.toUtc(), equals(newStart.toUtc()));
    expect(updated.endTime?.toUtc(), equals(newEnd.toUtc()));
    expect(updated.note, equals('Updated note'));
  });

  // Test: update throws for non-existent timelog
  test('update throws exception for non-existent timelog', () async {
    expect(
      () => timelogRepo.update(conn, id: 9999, note: 'X'),
      throwsA(predicate((e) => e is IdNotFoundException)),
    );
  });

  // Test: delete timelog successfully
  test('delete removes a timelog', () async {
    final now = DateTime.now();
    await timelogRepo.insert(
      conn,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      note: 'To Delete',
    );
    final timelog = (await timelogRepo.findAll(conn)).single;

    await timelogRepo.delete(conn, timelog.id);

    expect(
      () => timelogRepo.findById(conn, timelog.id),
      throwsA(predicate((e) => e is IdNotFoundException)),
    );
  });

  // Test: delete throws for non-existent timelog
  test('delete throws exception for non-existent timelog', () async {
    expect(
      () => timelogRepo.delete(conn, 9999),
      throwsA(predicate((e) => e is IdNotFoundException)),
    );
  });

  // Test: insert multiple timelogs quickly
  test('insert multiple timelogs quickly and verify all are present', () async {
    final now = DateTime.now();
    for (int i = 1; i <= 5; i++) {
      await timelogRepo.insert(
        conn,
        startTime: now,
        endTime: now.add(Duration(hours: i)),
        note: 'TL $i',
      );
    }

    final timelogs = await timelogRepo.findAll(conn);
    expect(timelogs.length, equals(5));
    final sorted = [...timelogs]..sort((a, b) => a.id.compareTo(b.id));
    for (int i = 0; i < 5; i++) {
      expect(sorted[i].note, equals('TL ${i + 1}'));
    }
  });

  // Test: update only note
  test('updates only note when startTime and endTime are null', () async {
    final now = DateTime.now();
    await timelogRepo.insert(
      conn,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      note: 'Old',
    );
    final timelog = (await timelogRepo.findAll(conn)).single;

    await timelogRepo.update(conn, id: timelog.id, note: 'New');

    final updated = await timelogRepo.findById(conn, timelog.id);
    expect(updated.note, equals('New'));
    expect(updated.startTime, equals(timelog.startTime));
    expect(updated.endTime, equals(timelog.endTime));
  });

  // Test: update throws if no fields are provided
  test('update throws if no fields are provided', () async {
    final now = DateTime.now();
    await timelogRepo.insert(
      conn,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      note: 'Original',
    );
    final timelog = (await timelogRepo.findAll(conn)).single;

    expect(
      () => timelogRepo.update(conn, id: timelog.id),
      throwsA(predicate((e) => e is NullUpdateException)),
    );
  });

  // Test: delete all timelogs one by one
  test('delete all timelogs one by one', () async {
    final now = DateTime.now();
    for (int i = 1; i <= 3; i++) {
      await timelogRepo.insert(
        conn,
        startTime: now,
        endTime: now.add(Duration(hours: i)),
        note: 'TL $i',
      );
    }

    var timelogs = await timelogRepo.findAll(conn);
    expect(timelogs.length, equals(3));

    for (final tl in timelogs) {
      await timelogRepo.delete(conn, tl.id);
    }

    final remaining = await timelogRepo.findAll(conn);
    expect(remaining, isEmpty);
  });

  test('insert defaults endTime to null and note to empty string', () async {
    final start = DateTime.now();

    final inserted = await timelogRepo.insert(conn, startTime: start);

    expect(inserted.endTime, isNull);
    expect(inserted.note, equals(''));

    final fetched = await timelogRepo.findById(conn, inserted.id);
    expect(fetched.endTime, isNull);
    expect(fetched.note, equals(''));
  });

  test('insert returns the persisted timelog', () async {
    final start = DateTime.now();

    final returned = await timelogRepo.insert(
      conn,
      startTime: start,
      note: 'Hello',
    );

    final fetched = await timelogRepo.findById(conn, returned.id);

    expect(returned.id, equals(fetched.id));
    expect(returned.startTime.toUtc(), equals(fetched.startTime.toUtc()));
    expect(returned.note, equals(fetched.note));
  });

  test('update modifies only startTime', () async {
    final now = DateTime.now();
    await timelogRepo.insert(
      conn,
      startTime: now,
      endTime: now.add(const Duration(hours: 5)),
      note: 'Note',
    );

    final original = (await timelogRepo.findAll(conn)).single;
    final newStart = now.add(const Duration(hours: 2));

    await timelogRepo.update(conn, id: original.id, startTime: newStart);

    final updated = await timelogRepo.findById(conn, original.id);
    expect(updated.startTime.toUtc(), equals(newStart.toUtc()));
    expect(updated.endTime, equals(original.endTime));
    expect(updated.note, equals(original.note));
  });

  test('update modifies only endTime', () async {
    final now = DateTime.now();
    await timelogRepo.insert(
      conn,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      note: 'Note',
    );

    final original = (await timelogRepo.findAll(conn)).single;
    final newEnd = now.add(const Duration(hours: 3));

    await timelogRepo.update(conn, id: original.id, endTime: newEnd);

    final updated = await timelogRepo.findById(conn, original.id);
    expect(updated.endTime?.toUtc(), equals(newEnd.toUtc()));
    expect(updated.startTime, equals(original.startTime));
  });

  //test('update allows setting endTime to null', () async {
  //  final now = DateTime.now();
  //  await timelogRepo.insert(
  //    conn,
  //    startTime: now,
  //    endTime: now.add(const Duration(hours: 1)),
  //    note: 'Note',
  //  );
  //
  //  final original = (await timelogRepo.findAll(conn)).single;
  //
  //  await timelogRepo.update(conn, id: original.id, endTime: null);
  //
  //  final updated = await timelogRepo.findById(conn, original.id);
  //  expect(updated.endTime, isNull);
  //});

  test('delete removes only the specified timelog', () async {
    final now = DateTime.now();
    await timelogRepo.insert(conn, startTime: now, note: 'A');
    await timelogRepo.insert(conn, startTime: now, note: 'B');

    final timelogs = await timelogRepo.findAll(conn);
    final toDelete = timelogs.first;
    final toKeep = timelogs.last;

    await timelogRepo.delete(conn, toDelete.id);

    final remaining = await timelogRepo.findAll(conn);
    expect(remaining.length, equals(1));
    expect(remaining.single.id, equals(toKeep.id));
  });
}
