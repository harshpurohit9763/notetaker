import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class AudioEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => 'audio';

  @override
  Widget build(
    BuildContext context,
    quill.QuillController controller,
    quill.Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
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
  late PlayerController _playerController;

  String? get _audioPath => widget.node.value.data as String?;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _preparePlayer();

    _playerController.onPlayerStateChanged.listen((_) {
      setState(() {});
    });
  }

  void _preparePlayer() async {
    if (_audioPath != null) {
      await _playerController.preparePlayer(
        path: _audioPath!,
        shouldExtractWaveform: true,
        noOfSamples: 100, // To generate 100 samples from the audio file
        volume: 1.0,
      );
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_playerController.playerState.isPlaying) {
      await _playerController.pausePlayer();
    } else {
      await _playerController.startPlayer();
    }
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey.shade800)),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _playerController.playerState.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: widget.readOnly ? null : _togglePlayPause,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AudioFileWaveforms(
              size: const Size(double.infinity, 50.0),
              playerController: _playerController,
              enableSeekGesture: true,
              waveformType: WaveformType.long,
              playerWaveStyle: PlayerWaveStyle(
                liveWaveGradient: LinearGradient(colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ]).createShader(
                  const Rect.fromLTWH(0, 0, 0, 0),
                ),
                spacing: 4.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
