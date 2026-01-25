import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:workapp_backend/01_routing/fixtures_routes.dart';
import 'package:workapp_backend/02_Repositories/fixture_model_repository.dart';

import 'package:workapp_backend/database_connection.dart';
import 'package:workapp_backend/01_routing/notes_routes.dart';
import 'package:workapp_backend/02_Repositories/note_repository.dart';
import 'package:workapp_backend/01_routing/timelogs_routes.dart';
import 'package:workapp_backend/02_Repositories/timelog_repository.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  await initializeDateFormatting('sv_SE', null);
  final conn = await DatabaseConnection.get();
  final router = Router();

  // Register route groups
  NotesRoutes(NoteRepository(), conn).register(router);
  TimelogRoutes(TimelogRepository(), conn).register(router);
  FixturesRoutes(FixtureModelRepository(), conn).register(router);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final server = await io.serve(handler, '127.0.0.1', 3000);
  print('Server running on http://${server.address.host}:${server.port}');
}
