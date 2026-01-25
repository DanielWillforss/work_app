import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_models/models/note_model.dart';
import 'package:work_app/main.dart';

class NotesApi {
  static const String baseUrl = GlobalConstants.baseUrl;

  /// GET /notes
  static Future<List<Note>> getNotes() async {
    final response = await http.get(Uri.parse('$baseUrl/notes'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load notes');
    }

    final List data = jsonDecode(response.body);
    print(data);
    return data.map((e) => Note.fromMap(e)).toList();
  }

  /// POST /notes
  static Future<Note> createNote(String title, String body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'body': body}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create note');
    }

    final Note note = Note.fromMap(jsonDecode(response.body));
    return note;
  }

  /// PUT /notes/{id}
  static Future<Note> updateNote(int id, String title, String body) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'body': body}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update note');
    }

    final Note note = Note.fromMap(jsonDecode(response.body));
    return note;
  }

  /// DELETE /notes/{id}
  static Future<void> deleteNote(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/notes/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete note');
    }
  }
}
