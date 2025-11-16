import 'dart:convert';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:note_taker/note_provider.dart';
import 'package:note_taker/routes/route_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:note_taker/note_model.dart'; // Import Note model
import 'package:image_picker/image_picker.dart'; // Import image_picker

class CreateNoteViewModel extends ChangeNotifier {
  final _titleController = TextEditingController();
  late final quill.QuillController _quillController;
  String? _noteId; // To store the ID of the note being edited

  late final RecorderController _recorderController;
  bool _isRecordingUiVisible = false;
  quill.Attribute? _lastAppliedAttribute;

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _quillFocusNode = FocusNode();

  final ImagePicker _imagePicker = ImagePicker(); // Image picker instance

  TextEditingController get titleController => _titleController;
  quill.QuillController get quillController => _quillController;
  RecorderController get recorderController => _recorderController;
  bool get isRecordingUiVisible => _isRecordingUiVisible;
  FocusNode get titleFocusNode => _titleFocusNode;
  FocusNode get quillFocusNode => _quillFocusNode;

  CreateNoteViewModel({
    String? templateTitle,
    String? templateContent,
    Note? note, // New optional parameter for editing
  }) {
    _recorderController = RecorderController();
    if (note != null) {
      _noteId = note.id;
      _titleController.text = note.title;
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
    }

    _quillController.addListener(() {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _recorderController.dispose();
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

  void toggleRecordingUi() {
    _isRecordingUiVisible = !_isRecordingUiVisible;
    if (_isRecordingUiVisible) {
      startRecording();
    } else {
      stopRecording(embed: false);
    }
    notifyListeners();
  }

  Future<void> startRecording() async {
    final hasPermission = await _recorderController.checkPermission();
    if (hasPermission) {
      final dir = await getApplicationSupportDirectory();
      final path =
          '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorderController.record(path: path);
    }
    notifyListeners();
  }

  Future<void> togglePauseResume() async {
    if (_recorderController.recorderState.isPaused) {
      await _recorderController.record();
    } else {
      await _recorderController.pause();
    }
    notifyListeners();
  }

  Future<void> stopRecording({bool embed = true}) async {
    final path = await _recorderController.stop();
    if (embed && path != null) {
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      _quillController.replaceText(
        index,
        length,
        quill.BlockEmbed('audio', path),
        null,
      );
    }
    _isRecordingUiVisible = false;
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

    final content = jsonEncode(_quillController.document.toDelta().toJson());
    if (_noteId != null) {
      noteProvider.updateNote(_noteId!, title, content, 'text');
    } else {
      noteProvider.addTextNote(title, content);
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
    _quillController.compose(
        todoDelta, currentSelection, quill.ChangeSource.local);
    _quillController.updateSelection(
      TextSelection.collapsed(
          offset: currentSelection.baseOffset + todoDelta.length),
      quill.ChangeSource.local,
    );
  }
}
