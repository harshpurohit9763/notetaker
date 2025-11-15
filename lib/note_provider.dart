import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'note_model.dart';
import 'package:uuid/uuid.dart';

class NoteProvider with ChangeNotifier {
  final Box<Note> _notesBox = Hive.box<Note>('notes');
  final _uuid = Uuid();

  List<Note> get notes => _notesBox.values.toList()
    ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

  Future<void> addTextNote(String title, String content) async {
    final newNote = Note()
      ..id = _uuid.v4()
      ..title = title
      ..content = content
      ..createdAt = DateTime.now()
      ..lastUpdatedAt = DateTime.now()
      ..noteType = 'text';

    await _notesBox.put(newNote.id, newNote);
    notifyListeners();
  }

  Future<void> addVoiceNote(String title, String audioPath) async {
    final newNote = Note()
      ..id = _uuid.v4()
      ..title = title
      ..content = audioPath
      ..createdAt = DateTime.now()
      ..lastUpdatedAt = DateTime.now()
      ..noteType = 'voice';

    await _notesBox.put(newNote.id, newNote);
    notifyListeners();
  }

  Future<void> updateNote(
      String id, String title, String content, String noteType) async {
    final existingNote = _notesBox.get(id);
    if (existingNote != null) {
      existingNote.title = title;
      existingNote.content = content;
      existingNote.noteType = noteType;
      existingNote.lastUpdatedAt = DateTime.now();
      await existingNote.save(); // Save changes to Hive
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
    notifyListeners();
  }

  Future<void> archiveNote(String id, bool archive) async {
    final existingNote = _notesBox.get(id);
    if (existingNote != null) {
      existingNote.isArchived = archive;
      existingNote.lastUpdatedAt = DateTime.now(); // Update last updated time
      await existingNote.save();
      notifyListeners();
    }
  }

  Future<void> toggleLockNote(String id) async {
    final existingNote = _notesBox.get(id);
    if (existingNote != null) {
      existingNote.isLocked = !(existingNote.isLocked ?? false);
      existingNote.lastUpdatedAt = DateTime.now(); // Update last updated time
      await existingNote.save();
      notifyListeners();
    }
  }
}
