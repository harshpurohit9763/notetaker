import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:audioplayers/audioplayers.dart';

class AudioEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => 'audio';

  @override
  Widget build(
    BuildContext context,
    quill.QuillController controller,
    quill.Embed node,
    bool readOnly,
    bool inline, // Keep this parameter
    TextStyle textStyle, // Change DefaultStyles? styles to TextStyle textStyle
  ) {
    return CustomAudioEmbedBuilder(
      node: node,
      readOnly: readOnly,
    );
  }
}

class CustomAudioEmbedBuilder extends StatefulWidget {
  final quill.Embed node;
  final bool readOnly;

  const CustomAudioEmbedBuilder({
    Key? key,
    required this.node,
    required this.readOnly,
  }) : super(key: key);

  @override
  State<CustomAudioEmbedBuilder> createState() =>
      _CustomAudioEmbedBuilderState();
}

class _CustomAudioEmbedBuilderState extends State<CustomAudioEmbedBuilder> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  String? get _audioPath => widget.node.value.data as String?;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
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
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_audioPath == null) return;

    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      if (_position > Duration.zero && _position < _duration) {
        _audioPlayer.resume();
      } else {
        _audioPlayer.play(DeviceFileSource(_audioPath!));
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_audioPath == null || _audioPath!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: widget.readOnly ? null : _togglePlayPause,
              ),
              Expanded(
                child: Slider(
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
                  value: _position.inSeconds
                      .toDouble()
                      .clamp(0.0, _duration.inSeconds.toDouble()),
                  onChanged: widget.readOnly
                      ? null
                      : (value) {
                          final position = Duration(seconds: value.toInt());
                          _audioPlayer.seek(position);
                        },
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey,
                ),
              ),
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          Text(
            _audioPath!.split('/').last, // Display file name
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
