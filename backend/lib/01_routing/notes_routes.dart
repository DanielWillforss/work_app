import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:workapp_backend/02_Repositories/note_repository.dart';
import 'package:workapp_backend/util/general_util.dart';
import 'package:workapp_backend/util/parse_util.dart';

class NotesRoutes {
  final NoteRepository notesRepo;
  final Connection conn;

  NotesRoutes(this.notesRepo, this.conn);

  void register(Router router) {
    // GET /notes
    router.get('/notes', _getAll);

    // GET /notes/<id>
    router.get('/notes/<id>', _getById);

    // POST /notes
    router.post('/notes', _create);

    // PUT /notes/<id>
    router.put('/notes/<id>', _update);

    // DELETE /notes/<id>
    router.delete('/notes/<id>', _delete);
  }

  /// returns all notes as a list of json with the keys "id", "title", "body", "created_at", "updated_at"
  Future<Response> _getAll(Request req) async {
    final notes = await notesRepo.findAll(conn);
    return jsonResponse(notes.map((n) => n.toJson()).toList());
  }

  /// return the note with the specific id as json with the keys "id", "title", "body", "created_at", "updated_at"
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  Future<Response> _getById(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      final note = await notesRepo.findById(conn, parsedId.value!);
      return jsonResponse(note.toJson());
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    }
  }

  /// returns created note as json
  /// returns badRequest('Request not formatted correctly') if req could not be parsed or contained other keys than title and body
  Future<Response> _create(Request req) async {
    final payload = await decodeRequest(req, allowedKeys: {'title', 'body'});
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    final note = await notesRepo.insert(
      conn,
      title: payload['title'],
      body: payload['body'],
    );
    return jsonResponse(note.toJson());
  }

  /// returns the updated note as json
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'null_update'}) if neither title nor body was given
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  /// returns badRequest('Request not formatted correctly') if req could not be parsed or contained other keys than title and body
  Future<Response> _update(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    final payload = await decodeRequest(req, allowedKeys: {'title', 'body'});
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    try {
      final note = await notesRepo.update(
        conn,
        id: parsedId.value!,
        title: payload['title'],
        body: payload['body'],
      );
      return jsonResponse(note.toJson());
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    } on NullUpdateException {
      return jsonResponse({'status': 'null_update'});
    }
  }

  /// returns jsonResponse({'status': 'deleted'})
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  Future<Response> _delete(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      await notesRepo.delete(conn, parsedId.value!);
      return jsonResponse({'status': 'deleted'});
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    }
  }
}
