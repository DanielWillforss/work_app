import 'package:postgres/postgres.dart';

class DatabaseConnection {
  static Connection? _conn;

  static Future<Connection> get() async {
    _conn ??= await Connection.open(
      Endpoint(
        host: 'localhost',
        port: 5432,
        database: 'workapp_dev',
        username: 'admin',
        password: 'admin',
      ),
    );

    return _conn!;
  }

  //TODO: what if connection fails or is lost?
  // Consistent error message thrown by repository?
}
