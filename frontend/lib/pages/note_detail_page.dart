import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_models/models/note_model.dart';
import 'package:work_app/services/notes_api.dart';

class NoteDetailPage extends StatefulWidget {
  final Note note;

  const NoteDetailPage({super.key, required this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController _contentController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note.body);

    // Add listeners for real-time updates
    _contentController.addListener(_onChange);
  }

  void _onChange() {
    // Debounce to avoid sending HTTP requests on every keystroke
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _updateNote();
    });
  }

  Future<void> _updateNote() async {
    try {
      await NotesApi.updateNote(
        widget.note.id,
        widget.note.title,
        _contentController.text,
      );
    } catch (e) {
      // Handle error, maybe show a SnackBar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update note')));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Note')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.note.title),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start writing your note...',
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null, // unlimited lines
              ),
            ),
          ],
        ),
      ),
    );
  }
}
