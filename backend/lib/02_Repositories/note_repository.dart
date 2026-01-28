// import 'package:postgres/postgres.dart';
// import 'package:shared_models/models/note_model.dart';
// import 'package:workapp_backend/util/general_util.dart';

// class NoteRepository {
//   // Get all as List of Notes
//   Future<List<Note>> findAll(Connection conn) async {
//     final result = await conn.execute(
//       Sql.named('SELECT * FROM content.notes ORDER BY created_at DESC'),
//     );

//     return result.map((row) => Note.fromSql(row.toColumnMap())).toList();
//   }

//   // returns Note by id
//   // throws IdNotFoundException for non-existant id
//   Future<Note> findById(Connection conn, int id) async {
//     final result = await conn.execute(
//       Sql.named('SELECT * FROM content.notes WHERE id = @id'),
//       parameters: {'id': id},
//     );

//     if (result.isEmpty) throw IdNotFoundException(id);
//     return Note.fromSql(result.first.toColumnMap());
//   }

//   /// Adds new note
//   /// Sets title and content to '' if null or not sent as parameters
//   /// Sets createdAt and updatedAt to now()
//   /// Returns updated Note
//   Future<Note> insert(Connection conn, {String? title, String? body}) async {
//     final result = await conn.execute(
//       Sql.named('''
//         INSERT INTO content.notes (title, body)
//         VALUES (@title, @body)
//         RETURNING *
//         '''),
//       parameters: {'title': title ?? '', 'body': body ?? ''},
//     );

//     return Note.fromSql(result.first.toColumnMap());
//   }

//   /// Update title and/or content of a note
//   /// Sets updatedAt to clock_timestamp()
//   /// throws IdNotFoundException for non-existant id
//   /// throws NullUpdateExeption if nothing is updated
//   /// Returns updated Note
//   Future<Note> update(
//     Connection conn, {
//     required int id,
//     String? title,
//     String? body,
//   }) async {
//     // Collect fields to update
//     final fields = <String>[];
//     final parameters = <String, dynamic>{'id': id};

//     if (title != null) {
//       fields.add('title = @title');
//       parameters['title'] = title;
//     }

//     if (body != null) {
//       fields.add('body = @body');
//       parameters['body'] = body;
//     }

//     if (fields.isEmpty) {
//       throw NullUpdateException();
//     }

//     // Always update the timestamp
//     fields.add('updated_at = clock_timestamp()');

//     final sql =
//         '''
//       UPDATE content.notes
//       SET ${fields.join(', ')}
//       WHERE id = @id
//       RETURNING *
//     ''';

//     final result = await conn.execute(Sql.named(sql), parameters: parameters);

//     if (result.isEmpty) {
//       throw IdNotFoundException(id);
//     }

//     return Note.fromSql(result.first.toColumnMap());
//   }

//   // Delete a note
//   // throws IdNotFoundException for non-existant id
//   Future<void> delete(Connection conn, int id) async {
//     final result = await conn.execute(
//       Sql.named('DELETE FROM content.notes WHERE id = @id'),
//       parameters: {'id': id},
//     );
//     if (result.affectedRows == 0) {
//       throw IdNotFoundException(id);
//     }
//   }
// }
