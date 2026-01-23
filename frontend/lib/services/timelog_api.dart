import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/timelog.dart';

class TimelogsApi {
  static const String baseUrl = 'http://192.168.50.71:8080';

  /// GET /timelogs
  static Future<List<Timelog>> getTimelogs() async {
    final response = await http.get(Uri.parse('$baseUrl/timelogs'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load timelogs');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => Timelog.fromJson(e)).toList();
  }

  /// POST /timelogs
  static Future<void> createTimelog({
    DateTime? startTime,
    DateTime? endTime,
    String? note,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/timelogs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'note': note,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create timelog');
    }
  }

  /// PUT /timelogs/{id}
  static Future<void> updateTimelog(
    int id, {
    required DateTime startTime,
    DateTime? endTime,
    String? note,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/timelogs/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'note': note,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update timelog');
    }
  }

  /// DELETE /timelogs/{id}
  static Future<void> deleteTimelog(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/timelogs/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete timelog');
    }
  }

  /// // POST /timelogs/upload
  static Future<void> uploadTimelogs() async {
    final response = await http.post(Uri.parse('$baseUrl/timelogs/upload'));

    if (response.statusCode != 200) {
      throw Exception('Failed to upload timelogs');
    }
  }
}
