import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:note_taker/note_model.dart';
import 'package:note_taker/utils/route_manager.dart';

class NotePreviewScreen extends StatefulWidget {
  final Note note;

  const NotePreviewScreen({Key? key, required this.note}) : super(key: key);

  @override
  State<NotePreviewScreen> createState() => _NotePreviewScreenState();
}

class _NotePreviewScreenState extends State<NotePreviewScreen> {
  QuillController? _quillController;
  late FocusNode _focusNode;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    if (widget.note.noteType == 'text' && widget.note.content.isNotEmpty) {
      try {
        _quillController = QuillController(
          document: Document.fromJson(jsonDecode(widget.note.content)),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _quillController = QuillController.basic();
      }
    } else {
      _quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _quillController?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // app-black
      appBar: AppBar(
        backgroundColor: Colors.black, // app-black
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(''), // Empty title to center actions
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to edit screen
              Navigator.pushNamed(
                context,
                RouteManager.createNoteScreen,
                arguments: widget.note, // Pass the note for editing
              );
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Color(0xFF0A84FF), // app-blue
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // More options
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.note.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy')
                      .format(widget.note.createdAt ?? DateTime.now()),
                  style: const TextStyle(
                    color: Color(0xFF8E8E93), // app-gray-text
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Updated: ${DateFormat('MMM dd, yyyy').format(widget.note.lastUpdatedAt ?? DateTime.now())}',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93), // app-gray-text
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.note.noteType == 'text'
                  ? AbsorbPointer(
                      child: QuillEditor(
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        // padding: EdgeInsets.zero,
                        configurations: QuillEditorConfigurations(
                          controller: _quillController!,
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.multitrack_audio,
                            color: Color(0xFF8E8E93),
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Voice Note',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.note.content
                                .split('/')
                                .last, // Display file name
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 16,
                            ),
                          ),
                          // TODO: Add playback functionality for voice notes
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
