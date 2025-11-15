import 'package:flutter/material.dart';
import 'package:note_taker/create_note_screen.dart';
import 'package:note_taker/home_screen.dart';
import 'package:note_taker/main.dart';

class RouteManager {
  static const String homeScreen = '/';
  static const String createNoteScreen = '/create-note';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homeScreen:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case createNoteScreen:
        return MaterialPageRoute(builder: (_) => const CreateNoteScreen());
      default:
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
