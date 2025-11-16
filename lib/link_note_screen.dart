import 'package:flutter/material.dart';
import 'package:note_taker/note_model.dart';
import 'package:note_taker/note_provider.dart';
import 'package:provider/provider.dart';

class LinkNoteScreen extends StatelessWidget {
  const LinkNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Link Note'),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          if (noteProvider.notes.isEmpty) {
            return const Center(
              child: Text('No notes available to link.', style: TextStyle(color: Colors.white)),
            );
          }
          return ListView.builder(
            itemCount: noteProvider.notes.length,
            itemBuilder: (context, index) {
              final note = noteProvider.notes[index];
              return ListTile(
                title: Text(note.title, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context, note); // Return the whole note object
                },
              );
            },
          );
        },
      ),
    );
  }
}
