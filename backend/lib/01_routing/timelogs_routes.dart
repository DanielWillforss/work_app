import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:workapp_backend/02_Repositories/timelog_repository.dart';
import 'package:workapp_backend/util/general_util.dart';
import 'package:workapp_backend/util/google_sheets_api.dart';
import 'package:workapp_backend/util/parse_util.dart';

class TimelogRoutes {
  final TimelogRepository timelogRepo;
  final Connection conn;

  TimelogRoutes(this.timelogRepo, this.conn);

  void register(Router router) {
    // GET /timelogs
    router.get('/timelogs', _getAll);

    // GET /timelogs/<id>
    router.get('/timelogs/<id>', _getById);

    // POST /timelogs
    router.post('/timelogs', _create);

    // PUT /timelogs/<id>
    router.put('/timelogs/<id>', _update);

    // DELETE /timelogs/<id>
    router.delete('/timelogs/<id>', _delete);

    // POST /timelogs/upload
    router.post('/timelogs/upload', _upload);
  }

  /// returns all timelogs as a list of json with the keys "id", "start_time", "end_time", "note"
  Future<Response> _getAll(Request req) async {
    final logs = await timelogRepo.findAll(conn);
    return jsonResponse(logs.map((l) => l.toJson()).toList());
  }

  /// return the timelog with the specific id as json with the keys "id", "start_time", "end_time", "note"
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  Future<Response> _getById(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      final log = await timelogRepo.findById(conn, parsedId.value!);
      return jsonResponse(log.toJson());
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    }
  }

  /// returns jsonResponse({'status': 'ok'})
  /// returns badRequest('Request not formatted correctly') if req could not be parsed or contained other keys than expected
  /// returns badRequest('Invalid Datetime') if starttime or endtime is not formatted correctly
  /// return Response.badRequest(body: 'StartTime must not be null') if starttime is null;
  Future<Response> _create(Request req) async {
    final payload = await decodeRequest(
      req,
      allowedKeys: {'start_time', 'end_time', 'note'},
    );
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    final startTime = parseDatetime(payload['start_time']);
    if (startTime.value == null) {
      return Response.badRequest(body: 'StartTime must not be null');
    }
    if (!startTime.isOk) return startTime.error!;
    final endTime = parseDatetime(payload['end_time']);
    if (!endTime.isOk) return endTime.error!;

    await timelogRepo.insert(
      conn,
      startTime: startTime.value!,
      endTime: endTime.value,
      note: payload['note'],
    );

    return jsonResponse({'status': 'ok'});
  }

  /// returns jsonResponse({'status': 'updated'})
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  /// returns badRequest('Invalid Datetime') if starttime or endtime is not formatted correctly
  /// returns jsonResponse({'status': 'null_update'}) for empty updates
  Future<Response> _update(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    final payload = await decodeRequest(
      req,
      allowedKeys: {'start_time', 'end_time', 'note'},
    );
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    final startTime = parseDatetime(payload['start_time']);
    if (!startTime.isOk) return startTime.error!;
    final endTime = parseDatetime(payload['end_time']);
    if (!endTime.isOk) return endTime.error!;

    try {
      await timelogRepo.update(
        conn,
        id: parsedId.value!,
        startTime: startTime.value,
        endTime: endTime.value,
        note: payload['note'],
      );
      return jsonResponse({'status': 'updated'});
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    } on NullUpdateException {
      return jsonResponse({'status': 'null_update'});
    }
  }

  /// returns jsonResponse({'status': 'deleted'})
  /// returns badRequest('Invalid note id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  Future<Response> _delete(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      await timelogRepo.delete(conn, parsedId.value!);
      return jsonResponse({'status': 'deleted'});
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    }
  }

  Future<Response> _upload(Request req) async {
    print("uploading");
    try {
      final googleApi = GoogleApiHandeler();
      await googleApi.init();

      final logs = await timelogRepo.findAll(conn);
      print("trying to write");
      await googleApi.writeData(logs);
      return jsonResponse({'status': 'uploaded'});
    } on IdNotFoundException {
      return Response.badRequest(body: 'upload failed');
    }
  }
}
