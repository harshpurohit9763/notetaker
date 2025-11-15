import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:intl/intl.dart';
import 'package:note_taker/note_model.dart';
import 'package:note_taker/routes/route_manager.dart';
import 'package:provider/provider.dart';
import 'package:note_taker/note_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';

class NoteActionModal extends StatefulWidget {
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
  State<NoteActionModal> createState() => _NoteActionModalState();
}

class _NoteActionModalState extends State<NoteActionModal> {
  // Audio playback variables
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
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
    if (widget.note.noteType == 'voice') {
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  String? _getFirstImageUrlFromDelta(String deltaJson) {
    try {
      final List<dynamic> jsonList = jsonDecode(deltaJson);
      final Document document = Document.fromDelta(Delta.fromJson(jsonList));

      for (final operation in document.toDelta().toList()) {
        if (operation.data is Map && (operation.data as Map).containsKey('image')) {
          return (operation.data as Map)['image'] as String;
        }
      }
    } catch (e) {
      print('Error parsing Delta JSON for image in NoteActionModal: $e');
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    return GestureDetector(
        onTap: widget.onDismiss, // Dismiss modal when tapping outside
        child: Material(
          color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
          child: Center(
            child: GestureDetector(
              onTap:
                  () {}, // Prevent dismissing when tapping on the modal content
              child: Hero(
                tag: widget.heroTag,
                child: SingleChildScrollView(
                  child: Container(
                    width: MediaQuery.of(context).size.width - 32.0, // Explicitly set width
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface, // app-gray
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Added this line
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
                                widget.note.title,
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
                              // Image preview, text content, or voice memo controls
                              widget.note.noteType == 'text'
                                  ? Builder(
                                      builder: (context) {
                                        final imageUrl = _getFirstImageUrlFromDelta(widget.note.content);
                                        if (imageUrl != null && imageUrl.isNotEmpty) {
                                          return SizedBox(
                                            width: 100,
                                            height: 100,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                File(imageUrl),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Text(
                                            _getPlainTextFromDelta(widget.note.content).length > 100
                                                ? '${_getPlainTextFromDelta(widget.note.content).substring(0, 100)}...'
                                                : _getPlainTextFromDelta(widget.note.content),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                              fontSize: 14,
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  : Material( // Added Material widget here for voice memo controls
                                      color: Colors.transparent,
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.multitrack_audio,
                                            color: Color(0xFF8E8E93),
                                            size: 40,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            widget.note.content
                                                .split('/')
                                                .last, // Display file name
                                            style: const TextStyle(
                                              color: Color(0xFF8E8E93),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: 30,
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
                                                  size: 30,
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
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(widget.note.createdAt ?? DateTime.now()),
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
                        Material( // Added Material widget here
                          color: Colors.transparent, // Make it transparent to not obscure the gradient
                          child: Container(
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
                                Expanded(
                                  child: IconButton(
                                    icon: Icon(
                                      (widget.note.isLocked ?? false)
                                          ? Icons.edit_off
                                          : Icons.edit,
                                      color: (widget.note.isLocked ?? false)
                                          ? Colors.grey
                                          : Colors.white,
                                    ),
                                    onPressed: (widget.note.isLocked ?? false)
                                        ? null
                                        : () {
                                            widget.onDismiss();
                                            Navigator.pushNamed(
                                              context,
                                              RouteManager.createNoteScreen,
                                              arguments: widget.note,
                                            );
                                          },
                                  ),
                                ),
                                // Lock
                                Expanded(
                                  child: IconButton(
                                    icon: Icon(
                                      (widget.note.isLocked ?? false)
                                          ? Icons.lock
                                          : Icons.lock_open_outlined,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      noteProvider.toggleLockNote(widget.note.id);
                                      widget.onDismiss();
                                    },
                                  ),
                                ),
                                // Archive
                                Expanded(
                                  child: IconButton(
                                    icon: Icon(
                                      (widget.note.isArchived ?? false)
                                          ? Icons.unarchive_outlined
                                          : Icons.archive_outlined,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      noteProvider.archiveNote(
                                          widget.note.id, !(widget.note.isArchived ?? false));
                                      widget.onDismiss();
                                    },
                                  ),
                                ),
                                // Delete
                                Expanded(
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      noteProvider.deleteNote(widget.note.id);
                                      widget.onDismiss();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
