import 'package:app_core/database/database.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:workapp_backend/01_routing/timelogs_routes.dart';
import 'package:workapp_backend/02_Repositories/timelog_repository.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  await initializeDateFormatting('sv_SE', null);
  //final conn = await DatabaseConnection.get();
  final router = Router();

  Database.init(
    Endpoint(
        host: 'localhost',
        port: 5432,
        database: 'dev_db',
        username: 'admin',
        password: 'admin',
      ),
  );

  TimelogRoutes(TimelogRepository()).register(router);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final server = await io.serve(handler, '127.0.0.1', 3000);
  print('Server running on http://${server.address.host}:${server.port}');
}
