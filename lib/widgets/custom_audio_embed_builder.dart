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
  Duration _currentDuration = Duration.zero;
  Duration _maxDuration = Duration.zero;

  String? get _audioPath => widget.node.value.data as String?;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _preparePlayer();

    _playerController.onPlayerStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
    _playerController.onCurrentDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _currentDuration = Duration(milliseconds: duration);
        });
      }
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
      if (mounted) {
        setState(() {
          _maxDuration = Duration(milliseconds: _playerController.maxDuration);
        });
      }
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

    const appGray = Color(0xFF1C1C1E);
    const appBlue = Color(0xFF0A84FF);
    const appGrayText = Color(0xFF8E8E93);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: appGray,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              // Play/Pause Button
              Container(
                decoration: const BoxDecoration(
                  color: appBlue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _playerController.playerState.isStopped || _playerController.playerState.isPaused
                        ? Icons.play_arrow
                        : Icons.pause,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: widget.readOnly ? null : _togglePlayPause,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
              const SizedBox(width: 12),
              // Waveform and Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentDuration),
                          style: const TextStyle(color: appGrayText, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(_maxDuration),
                          style: const TextStyle(color: appGrayText, fontSize: 12),
                        ),
                      ],
                    ),
                    // Waveform
                    AudioFileWaveforms(
                      size: const Size(double.infinity, 30.0),
                      playerController: _playerController,
                      enableSeekGesture: true,
                      waveformType: WaveformType.long,
                      playerWaveStyle: const PlayerWaveStyle(
                        fixedWaveColor: appGrayText,
                        liveWaveColor: appBlue,
                        spacing: 3.0,
                        waveThickness: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
