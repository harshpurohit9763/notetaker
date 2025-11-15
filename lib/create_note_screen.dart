import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'note_provider.dart';

class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({super.key});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _noteType = 'text'; // 'text' or 'voice'

  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _audioRecorder.start(const RecordConfig(), path: path);

      setState(() {
        _isRecording = true;
        _audioPath = null;
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
  }

  void _saveNote() {
    final title = _titleController.text;
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    if (_noteType == 'text') {
      final content = _contentController.text;
      if (content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content cannot be empty')),
        );
        return;
      }
      noteProvider.addTextNote(title, content);
    } else {
      if (_audioPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please record a voice memo')),
        );
        return;
      }
      noteProvider.addVoiceNote(title, _audioPath!);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_noteType == 'text')
              _buildTextEditor()
            else
              _buildVoiceRecorder(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'text', icon: Icon(Icons.text_fields), label: Text('Text')),
        ButtonSegment(value: 'voice', icon: Icon(Icons.mic), label: Text('Voice')),
      ],
      selected: {_noteType},
      onSelectionChanged: (newSelection) {
        setState(() {
          _noteType = newSelection.first;
        });
      },
    );
  }

  Widget _buildTextEditor() {
    return TextField(
      controller: _contentController,
      decoration: const InputDecoration(
        labelText: 'Content',
        border: OutlineInputBorder(),
      ),
      maxLines: 10,
    );
  }

  Widget _buildVoiceRecorder() {
    return Column(
      children: [
        if (_isRecording)
          const Text('Recording...', style: TextStyle(color: Colors.red)),
        if (_audioPath != null)
          Text('Recording saved at: $_audioPath'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? Colors.red : Colors.blue,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(24),
          ),
          child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 40),
        ),
      ],
    );
  }
}