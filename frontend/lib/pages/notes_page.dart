import 'package:flutter/material.dart';
import 'package:shared_models/models/note_model.dart';
import 'package:work_app/pages/note_detail_page.dart';
import '../services/notes_api.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late Future<List<Note>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    _notesFuture = NotesApi.getNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialogWindow(null),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Note>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          //Buffer
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          //If error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          //List empty
          final notes = snapshot.data!;
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet'));
          }

          //Build list
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(
                  note.body,
                  maxLines: 2, // show only 2 lines
                  overflow: TextOverflow.ellipsis, // add "..." if too long
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteDetailPage(note: note),
                    ),
                  );
                  setState(_loadNotes);
                },
                onLongPress: () => _showDialogWindow(note),
              );
            },
          );
        },
      ),
    );
  }

  void _showDialogWindow(Note? note) {
    final titleController = TextEditingController(text: note?.title);
    final bool isNewNote = note == null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isNewNote ? 'New Note' : 'Edit Title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
          ],
        ),
        actions: [
          isNewNote
              ? TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                )
              : TextButton(
                  onPressed: () async {
                    await NotesApi.deleteNote(note.id);
                    Navigator.pop(context);
                    setState(_loadNotes);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
          ElevatedButton(
            onPressed: () async {
              isNewNote
                  ? await NotesApi.createNote(titleController.text, "")
                  : await NotesApi.updateNote(
                      note.id,
                      titleController.text,
                      note.body,
                    );
              Navigator.pop(context);
              setState(_loadNotes);
            },
            child: Text(isNewNote ? 'Save' : 'Update'),
          ),
        ],
      ),
    );
  }
}
