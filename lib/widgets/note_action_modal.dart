import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:intl/intl.dart';
import 'package:note_taker/note_model.dart';
import 'package:note_taker/routes/route_manager.dart';
import 'package:provider/provider.dart';
import 'package:note_taker/note_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';

class NoteActionModal extends StatelessWidget {
  final Note note;
  final VoidCallback onDismiss;
  final String heroTag;

  const NoteActionModal({
    Key? key,
    required this.note,
    required this.onDismiss,
    required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    return GestureDetector(
        onTap: onDismiss, // Dismiss modal when tapping outside
        child: Material(
          color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
          child: Center(
            child: GestureDetector(
              onTap:
                  () {}, // Prevent dismissing when tapping on the modal content
              child: Hero(
                tag: heroTag,
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface, // app-gray
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating Card Clone
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getPlainTextFromDelta(note.content).length > 100
                                  ? '${_getPlainTextFromDelta(note.content).substring(0, 100)}...'
                                  : _getPlainTextFromDelta(note.content),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(note.createdAt ?? DateTime.now()),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Floating Action Icons
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Edit
                            IconButton(
                              icon: Icon(
                                (note.isLocked ?? false)
                                    ? Icons.edit_off
                                    : Icons.edit,
                                color: (note.isLocked ?? false)
                                    ? Colors.grey
                                    : Colors.white,
                              ),
                              onPressed: (note.isLocked ?? false)
                                  ? null
                                  : () {
                                      onDismiss();
                                      Navigator.pushNamed(
                                        context,
                                        RouteManager.createNoteScreen,
                                        arguments: note,
                                      );
                                    },
                            ),
                            // Lock
                            IconButton(
                              icon: Icon(
                                (note.isLocked ?? false)
                                    ? Icons.lock
                                    : Icons.lock_open_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                noteProvider.toggleLockNote(note.id);
                                onDismiss();
                              },
                            ),
                            // Archive
                            IconButton(
                              icon: Icon(
                                (note.isArchived ?? false)
                                    ? Icons.unarchive_outlined
                                    : Icons.archive_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                noteProvider.archiveNote(
                                    note.id, !(note.isArchived ?? false));
                                onDismiss();
                              },
                            ),
                            // Delete
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () {
                                noteProvider.deleteNote(note.id);
                                onDismiss();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  String _getPlainTextFromDelta(String deltaJson) {
    try {
      final List<dynamic> jsonList = jsonDecode(deltaJson);
      final Document document = Document.fromDelta(Delta.fromJson(jsonList));
      return document.toPlainText().trim();
    } catch (e) {
      // Handle parsing errors, e.g., if the content is not valid Delta JSON
      print('Error parsing Delta JSON: $e');
      return deltaJson; // Return original content if parsing fails
    }
  }
}
