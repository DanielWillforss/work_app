import 'package:postgres/postgres.dart';

abstract class Database {
  Future<Result> execute(Object query, {Object? parameters});
}

class DatabaseConnection implements Database {
  static final DatabaseConnection instance = DatabaseConnection();

  Connection? _conn;

  @override
  Future<Result> execute(Object query, {Object? parameters}) async {
    try {
      final conn = await _getConnection();
      return await conn.execute(query, parameters: parameters);
    } catch (e) {
      // Connection may have dropped — reset and retry once
      _conn = null;
      final conn = await _getConnection();
      return await conn.execute(query, parameters: parameters);
    }
  }

  //TODO: dont hard code credentials
  static Future<Connection> openConnection() async {
    return Connection.open(
      Endpoint(
        host: 'localhost',
        port: 5432,
        database: 'workapp_dev',
        username: 'admin',
        password: 'admin',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  Future<void> close() async {
    await _conn?.close();
    _conn = null;
  }

  Future<Connection> _getConnection() async {
    if (_conn == null || !_conn!.isOpen) {
      _conn = await openConnection();
    }
    return _conn!;
  }
}
