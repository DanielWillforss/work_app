import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:workapp_backend/02_Repositories/fixture_model_repository.dart';
import 'package:workapp_backend/util/general_util.dart';
import 'package:workapp_backend/util/parse_util.dart';

class FixturesRoutes {
  final FixtureModelRepository modelRepo;
  final Connection conn;

  FixturesRoutes(this.modelRepo, this.conn);

  void register(Router router) {
    // GET /fixtures/models
    router.get('/fixtures/models', _getAllModels);

    // GET /fixtures/types
    router.get('/fixtures/types', _getAllTypes);

    // GET /fixtures/manufacturers
    router.get('/fixtures/manufacturers', _getAllManufacturers);

    // GET /fixtures/models/<id>
    router.get('/fixtures/models/<id>', _getModelById);

    // GET /fixtures/models/type/<id>
    router.get('/fixtures/models/type/<id>', _getModelsByType);

    // GET /fixtures/models/manufacturer/<id>
    router.get('/fixtures/models/manufacturer/<id>', _getModelsByManufacturer);

    // POST /fixtures/models
    router.post('/fixtures/models', _createModel);

    // PUT /fixtures/models/<id>
    router.put('/fixtures/models/<id>', _updateModel);

    //DELETE /fixtures/models/<id>
    router.delete('/fixtures/models/<id>', _deleteModel);
  }

  /// returns all models as a list of json with the keys
  /// 'id', 'manufacturer_id', 'fixture_type_id', 'model_name',
  /// 'short_name', 'power_peak_amps', 'usual_dmx_mode', 'notes', 'created_at', 'updated_at'
  Future<Response> _getAllModels(Request req) async {
    final models = await modelRepo.findAll(conn);
    return jsonResponse(models.map((m) => m.toJson()).toList());
  }

  /// returns all types as a list of json with the keys 'id', 'name'
  Future<Response> _getAllTypes(Request req) async {
    final types = await modelRepo.findAllTypes(conn);
    return jsonResponse(types.map((m) => m.toJson()).toList());
  }

  /// returns all manufacturers as a list of json with the keys 'id', 'name'
  Future<Response> _getAllManufacturers(Request req) async {
    final manufacturers = await modelRepo.findAllManufacturers(conn);
    return jsonResponse(manufacturers.map((m) => m.toJson()).toList());
  }

  /// return the model with the specific id as json
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  Future<Response> _getModelById(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      final model = await modelRepo.findById(conn, parsedId.value!);
      return jsonResponse(model.toJson());
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    }
  }

  /// returns all models with the given type id as a list
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if no model was found
  Future<Response> _getModelsByType(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      final models = await modelRepo.findByType(conn, parsedId.value!);
      return jsonResponse(models.map((m) => m.toJson()).toList());
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    }
  }

  /// returns all models with the given manufacturer id as a list
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if no model was found
  Future<Response> _getModelsByManufacturer(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      final models = await modelRepo.findByManufacturer(conn, parsedId.value!);
      return jsonResponse(models.map((m) => m.toJson()).toList());
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    }
  }

  /// returns created note as json
  /// returns badRequest('Request not formatted correctly')
  /// if req could not be parsed or contained other keys than
  /// manufacturer_id,manufacturer_name,fixture_type_id,model_name,short_name,power_peak_amps,usual_dmx_mode,notes
  /// if manufacturer_id is given manufacturer_name is ignored
  /// if manufacturer_name does not exist, a new manufacturer will be created with that name
  /// manufacturer_id must correspond to an existing manufacturer
  /// fixture_type_id must correspond to an existing fixture_type
  /// returns badRequest('manufacturer_id or manufacturer_name, fixture_type_id and model_name are required') if those keys are not given
  Future<Response> _createModel(Request req) async {
    final payload = await decodeRequest(
      req,
      allowedKeys: {
        'manufacturer_id',
        'manufacturer_name',
        'fixture_type_id',
        'model_name',
        'short_name',
        'power_peak_amps',
        'usual_dmx_mode',
        'notes',
      },
    );
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    final manufacturerId = payload['manufacturer_id'];
    final manufacturerName = payload['manufacturer_name'];
    final typeId = payload['fixture_type_id'];
    final modelName = payload['model_name'];

    if ((manufacturerId == null && manufacturerName == null) ||
        typeId == null ||
        modelName == null) {
      return Response.badRequest(
        body:
            'manufacturer_id or manufacturer_name, fixture_type_id and model_name are required',
      );
    }

    final model = await modelRepo.insert(
      conn,
      manufacturer: manufacturerId != null
          ? ManufacturerById(manufacturerId)
          : ManufacturerByName(manufacturerName),
      fixtureTypeId: typeId,
      modelName: modelName,
      shortName: payload['short_name'],
      powerPeakAmps: payload['power_peak_amps'],
      usualDmxMode: payload['usual_dmx_mode'],
      notes: payload['notes'],
    );

    return jsonResponse(model.toJson());
  }

  /// returns the updated model as json
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'null_update'}) if no keys were given
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  /// if manufacturer_id is given manufacturer_name is ignored
  /// if manufacturer_name does not exist, a new manufacturer will be created with that name
  /// also deletes the corrosponding manufacturer if no model uses it anymore
  /// manufacturer_id must correspond to an existing manufacturer
  /// fixture_type_id must correspond to an existing fixture_type
  /// returns badRequest('Request not formatted correctly') if req could not be parsed or contained uunexpected keys
  Future<Response> _updateModel(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    final payload = await decodeRequest(
      req,
      allowedKeys: {
        'manufacturer_id',
        'manufacturer_name',
        'fixture_type_id',
        'model_name',
        'short_name',
        'power_peak_amps',
        'usual_dmx_mode',
        'notes',
      },
    );
    if (payload == null) {
      return Response.badRequest(body: 'Request not formatted correctly');
    }

    try {
      final manufacturerId = payload['manufacturer_id'];
      final manufacturerName = payload['manufacturer_name'];

      final ManufacturerRef? manufacturerRef;
      if (manufacturerId != null) {
        manufacturerRef = ManufacturerById(manufacturerId);
      } else if (manufacturerName != null) {
        manufacturerRef = ManufacturerByName(manufacturerName);
      } else {
        manufacturerRef = null;
      }

      final model = await modelRepo.update(
        conn,
        id: parsedId.value!,
        manufacturer: manufacturerRef,
        fixtureTypeId: payload['fixture_type_id'],
        modelName: payload['model_name'],
        shortName: payload['short_name'],
        powerPeakAmps: parseDouble(payload['power_peak_amps']).value,
        usualDmxMode: payload['usual_dmx_mode'],
        notes: payload['notes'],
      );
      return jsonResponse(model.toJson());
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    } on NullUpdateException {
      return jsonResponse({'status': 'null_update'});
    }
  }

  /// returns jsonResponse({'status': 'deleted'})
  /// also deletes the corrosponding manufacturer if no model uses it anymore
  /// returns badRequest('Invalid id') if the id is not an int
  /// returns jsonResponse({'status': 'not_found'}) if the id was not found
  Future<Response> _deleteModel(Request req, String id) async {
    final parsedId = parseId(id);
    if (!parsedId.isOk) return parsedId.error!;

    try {
      await modelRepo.delete(conn, parsedId.value!);
      return jsonResponse({'status': 'deleted'});
    } on IdNotFoundException {
      return jsonResponse({'status': 'not_found'});
    }
  }
}
