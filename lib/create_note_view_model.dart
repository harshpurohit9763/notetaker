import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:note_taker/note_provider.dart';
import 'package:note_taker/routes/route_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:note_taker/note_model.dart'; // Import Note model
import 'package:image_picker/image_picker.dart'; // Import image_picker

class CreateNoteViewModel extends ChangeNotifier {
  final _titleController = TextEditingController();
  late final quill.QuillController _quillController;
  String _noteType = 'text'; // 'text' or 'voice'
  String? _noteId; // To store the ID of the note being edited

  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  bool _showVoiceRecorder = false;
  bool _isPaused = false; // New state variable for pause/resume
  quill.Attribute? _lastAppliedAttribute;

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _quillFocusNode = FocusNode();

  final ImagePicker _imagePicker = ImagePicker(); // Image picker instance

  TextEditingController get titleController => _titleController;
  quill.QuillController get quillController => _quillController;
  String get noteType => _noteType;
  bool get isRecording => _isRecording;
  String? get audioPath => _audioPath;
  bool get showVoiceRecorder => _showVoiceRecorder;
  bool get isPaused => _isPaused; // New getter for isPaused
  FocusNode get titleFocusNode => _titleFocusNode;
  FocusNode get quillFocusNode => _quillFocusNode;

  CreateNoteViewModel({
    String? templateTitle,
    String? templateContent,
    String? templateNoteType,
    Note? note, // New optional parameter for editing
  }) {
    if (note != null) {
      _noteId = note.id;
      _titleController.text = note.title;
      _noteType = note.noteType;
      if (note.noteType == 'text') {
        try {
          _quillController = quill.QuillController(
            document: quill.Document.fromJson(
              jsonDecode(note.content),
            ),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } on FormatException {
          _quillController = quill.QuillController.basic();
        }
      } else {
        _quillController = quill.QuillController.basic();
        _audioPath = note.content;
        _showVoiceRecorder = true;
      }
    } else {
      // Existing template logic
      if (templateTitle != null) {
        _titleController.text = templateTitle;
      }
      if (templateContent != null && templateContent.isNotEmpty) {
        try {
          _quillController = quill.QuillController(
            document: quill.Document.fromJson(
              jsonDecode(templateContent),
            ),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } on FormatException {
          _quillController = quill.QuillController.basic();
        }
      } else {
        _quillController = quill.QuillController.basic();
      }
      if (templateNoteType != null) {
        _noteType = templateNoteType;
        if (_noteType == 'voice') {
          _showVoiceRecorder = true;
        }
      }
    }

    _quillController.addListener(() {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _audioRecorder.dispose();
    _titleFocusNode.dispose();
    _quillFocusNode.dispose();
    super.dispose();
  }

  void requestQuillFocus() {
    _quillFocusNode.requestFocus();
  }

  void toggleAttribute(quill.Attribute attribute, int tapCount) {
    if (tapCount == 1) {
      // Single tap: Toggle the attribute normally
      _quillController.formatSelection(attribute);
      _lastAppliedAttribute = attribute;
    } else if (tapCount == 2) {
      // Double tap: Remove the attribute
      _quillController.formatSelection(quill.Attribute.clone(attribute, null));
    } else if (tapCount == 3) {
      // Triple tap: Reapply the last applied attribute
      if (_lastAppliedAttribute != null) {
        _quillController.formatSelection(_lastAppliedAttribute!);
      }
    }
  }

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      if (_isPaused) {
        await _audioRecorder.resume();
        _isPaused = false;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final path =
            '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);
        _audioPath = null; // Clear previous audio path on new recording
      }
      _isRecording = true;
      notifyListeners();
    }
  }

  Future<void> pauseRecording() async {
    await _audioRecorder.pause();
    _isPaused = true;
    notifyListeners();
  }

  Future<void> stopRecording() async {
    final path = await _audioRecorder.stop();
    _isRecording = false;
    _isPaused = false;
    _audioPath = path;
    notifyListeners();
  }

  Future<void> insertImage() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // Get the current selection
    final int index = _quillController.selection.baseOffset;
    final int length = _quillController.selection.extentOffset - index;

    // Insert the image embed block
    _quillController.document.insert(index, quill.BlockEmbed.image(image.path));

    // Move the cursor after the inserted image
    _quillController.updateSelection(
      TextSelection.collapsed(offset: index + 1),
      quill.ChangeSource.local,
    );

    notifyListeners();
  }

  void saveNote(BuildContext context) {
    final title = _titleController.text;
    // If title is empty, set a default or handle as needed.
    // For now, we will allow empty titles as per user request.

    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    if (_noteType == 'text') {
      final content = jsonEncode(_quillController.document.toDelta().toJson());
      if (_noteId != null) {
        noteProvider.updateNote(_noteId!, title, content, _noteType);
      } else {
        noteProvider.addTextNote(title, content);
      }
    } else {
      if (_audioPath == null && !_isRecording && !_isPaused) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please record a voice memo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // If user is still recording or paused, stop it before saving
      if (_isRecording || _isPaused) {
        stopRecording().then((_) {
          if (_audioPath != null) {
            if (_noteId != null) {
              noteProvider.updateNote(_noteId!, title, _audioPath!, _noteType);
            } else {
              noteProvider.addVoiceNote(title, _audioPath!);
            }
          }
        });
      } else {
        if (_noteId != null) {
          noteProvider.updateNote(_noteId!, title, _audioPath!, _noteType);
        } else {
          noteProvider.addVoiceNote(title, _audioPath!);
        }
      }
    }

    if (_noteId != null) {
      // If editing an existing note, navigate to home screen and remove all previous routes
      Navigator.pushNamedAndRemoveUntil(
          context, RouteManager.homeScreen, (route) => false);
    } else {
      // If creating a new note, pop back to the previous screen (likely home)
      Navigator.pop(context);
    }
  }

  void setNoteTypeToVoice() {
    _noteType = 'voice';
    _showVoiceRecorder = true;
    notifyListeners();
  }

  void toggleVoiceRecorder() {
    _showVoiceRecorder = !_showVoiceRecorder;
    _noteType = _showVoiceRecorder ? 'voice' : 'text';
    notifyListeners();
  }

  void addTodoTemplate() {
    final todoDelta = Delta.fromJson([
      {
        "insert": "\n",
        "attributes": {"list": "checked", "checked": false}
      },
      {
        "insert": "\n",
        "attributes": {"list": "checked", "checked": false}
      },
      {
        "insert": "\n",
        "attributes": {"list": "checked", "checked": false}
      }
    ]);

    final currentSelection = _quillController.selection;
    _quillController.compose(todoDelta, currentSelection, quill.ChangeSource.local);
    _quillController.updateSelection(
      TextSelection.collapsed(
          offset: currentSelection.baseOffset + todoDelta.length),
      quill.ChangeSource.local,
    );
  }
}
