import 'package:postgres/postgres.dart';
import 'package:workapp_backend/00_models/timelog.dart';
import 'package:workapp_backend/util/general_util.dart';

class TimelogRepository {
  /// Get all timelogs as List
  Future<List<Timelog>> findAll(Connection conn) async {
    final result = await conn.execute(
      Sql.named('SELECT * FROM content.timelogs ORDER BY id DESC'),
    );

    return result.map((row) => Timelog.fromMap(row.toColumnMap())).toList();
  }

  /// Get a specific timelog by id
  /// throws IdNotFoundException if id is not found
  Future<Timelog> findById(Connection conn, int id) async {
    final result = await conn.execute(
      Sql.named('SELECT * FROM content.timelogs WHERE id = @id'),
      parameters: {'id': id},
    );

    if (result.isEmpty) throw IdNotFoundException(id);
    return Timelog.fromMap(result.first.toColumnMap());
  }

  /// Add a new timelog
  /// Empty endTIme defaults to null
  /// Empty note defaults to ''
  /// EndTime has to be after StartTime
  /// returns the updated timelog
  Future<Timelog> insert(
    Connection conn, {
    required DateTime startTime,
    DateTime? endTime,
    String? note,
  }) async {
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO content.timelogs (start_time, end_time, note)
        VALUES (@start_time, @end_time, @note)
        RETURNING *
      '''),
      parameters: {
        'start_time': startTime,
        'end_time': endTime,
        'note': note ?? '',
      },
    );
    return Timelog.fromMap(result.first.toColumnMap());
  }

  /// Update an existing timelog
  /// EndTime has to be after StartTime
  /// throws IdNotFoundException for non-existant id
  /// throws Exception("No change requested") if starttime, endtime, and note are null
  /// throws NullUpdateExeption if nothing is updated
  /// Returns updated Note
  Future<Timelog> update(
    Connection conn, {
    required int id,
    DateTime? startTime,
    DateTime? endTime,
    String? note,
  }) async {
    // Collect fields to update
    final fields = <String>[];
    final parameters = <String, dynamic>{'id': id};

    if (startTime != null) {
      fields.add('start_time = @start_time');
      parameters['start_time'] = startTime;
    }

    if (endTime != null) {
      fields.add('end_time = @end_time');
      parameters['end_time'] = endTime;
    }

    if (note != null) {
      fields.add('note = @note');
      parameters['note'] = note;
    }

    if (fields.isEmpty) {
      throw NullUpdateException();
    }

    final sql =
        '''
      UPDATE content.timelogs
      SET ${fields.join(', ')}
      WHERE id = @id
      RETURNING *
    ''';

    final result = await conn.execute(Sql.named(sql), parameters: parameters);

    if (result.affectedRows == 0) {
      throw IdNotFoundException(id);
    }

    return Timelog.fromMap(result.first.toColumnMap());
  }

  /// Delete a timelog by id
  /// throws IdNotFoundException for non-existant id
  Future<void> delete(Connection conn, int id) async {
    final result = await conn.execute(
      Sql.named('DELETE FROM content.timelogs WHERE id = @id'),
      parameters: {'id': id},
    );

    if (result.affectedRows == 0) {
      throw IdNotFoundException(id);
    }
  }
}
