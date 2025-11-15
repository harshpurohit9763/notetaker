import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:note_taker/note_model.dart';
import 'package:note_taker/routes/route_manager.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

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

  // Audio playback variables
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

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

    // Initialize audio player for voice notes
    if (widget.note.noteType == 'voice') {
      _audioPlayer = AudioPlayer();
      _initAudioPlayer();
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
      }
    });

    // Load audio source
    if (widget.note.content.isNotEmpty) {
      _audioPlayer.setSourceDeviceFile(widget.note.content);
    }
  }

  Future<void> _playAudio() async {
    if (widget.note.content.isNotEmpty) {
      await _audioPlayer.play(DeviceFileSource(widget.note.content));
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _position = Duration.zero;
        _isPlaying = false;
      });
    }
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _quillController?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    if (widget.note.noteType == 'voice') {
      _audioPlayer.dispose();
    }
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
                  : Column(
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
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                              onPressed: () {
                                if (_isPlaying) {
                                  _pauseAudio();
                                } else {
                                  _playAudio();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.stop,
                                color: Colors.white,
                                size: 40,
                              ),
                              onPressed: _stopAudio,
                            ),
                          ],
                        ),
                        Slider(
                          min: 0,
                          max: _duration.inSeconds.toDouble(),
                          value: _position.inSeconds.toDouble(),
                          onChanged: (value) {
                            final position = Duration(seconds: value.toInt());
                            _seek(position);
                          },
                          activeColor: Colors.blue,
                          inactiveColor: Colors.grey,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
