import 'package:flutter/material.dart';
import 'package:note_taker/note_model.dart';
import 'package:note_taker/widgets/note_action_modal.dart';

class NoteActionModalRoute extends PageRouteBuilder {
  final Note note;
  final String heroTag;

  NoteActionModalRoute({required this.note, required this.heroTag})
      : super(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) =>
              NoteActionModal(
            note: note,
            onDismiss: () => Navigator.pop(context),
            heroTag: heroTag, // Pass heroTag to the modal
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}
