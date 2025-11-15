import 'package:flutter/material.dart';
import 'package:note_taker/create_note_screen.dart';
import 'package:note_taker/home_screen.dart';
import 'package:note_taker/main.dart';
import 'package:note_taker/note_model.dart';
import 'package:note_taker/note_preview_screen.dart';

class RouteManager {
  static const String homeScreen = '/';
  static const String createNoteScreen = '/create-note';
  static const String notePreviewScreen = '/note-preview';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('Navigating to route: ${settings.name}');
    print('Arguments type: ${settings.arguments.runtimeType}');

    switch (settings.name) {
      case homeScreen:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case createNoteScreen:
        final args = settings.arguments;
        if (args is Note) {
          print('createNoteScreen: Arguments are Note type.');
          return MaterialPageRoute(
              builder: (_) => CreateNoteScreen(note: args));
        }
        print(
            'createNoteScreen: Arguments are NOT Note type. Creating new note.');
        return MaterialPageRoute(builder: (_) => const CreateNoteScreen());
      case notePreviewScreen:
        final args = settings.arguments;
        if (args is Note) {
          print(
              'notePreviewScreen: Arguments are Note type. Opening NotePreviewScreen.');
          return MaterialPageRoute(
              builder: (_) => NotePreviewScreen(note: args));
        }
        print(
            'notePreviewScreen: Arguments are NOT Note type. Showing error screen.');
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Error: Note not provided for NotePreviewScreen'),
            ),
          ),
        );
      default:
        print('Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
