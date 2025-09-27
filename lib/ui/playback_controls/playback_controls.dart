import 'package:flutter/material.dart';

class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onForward;
  final VoidCallback onRewind;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  // final ValueChanged<Duration>? onSeek;
  final bool isBusy;
  final VoidCallback? onSeekStart;
  final ValueChanged<Duration>? onSeekUpdate;
  final ValueChanged<Duration>? onSeekEnd;

  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onForward,
    required this.onRewind,
    required this.onNext,
    required this.onPrevious,
    //this.onSeek,
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: position.inSeconds
                  .toDouble()
                  .clamp(0, duration.inSeconds.toDouble()),
              min: 0,
              max: duration.inSeconds.toDouble() > 0
                  ? duration.inSeconds.toDouble()
                  : 1,
              onChangeStart: (_) => onSeekStart?.call(),
              onChanged: (value) =>
                  onSeekUpdate?.call(Duration(seconds: value.toInt())),
              onChangeEnd: (value) =>
                  onSeekEnd?.call(Duration(seconds: value.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(formatTime(position)),
                SizedBox(width: 16),
                IconButton(
                    icon: Icon(Icons.skip_previous), onPressed: onPrevious),
                IconButton(icon: Icon(Icons.replay_10), onPressed: onRewind),
                isBusy
                    ? const SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(
                            isPlaying ? Icons.pause_circle : Icons.play_circle),
                        iconSize: 40,
                        onPressed: onPlayPause,
                      ),
                IconButton(icon: Icon(Icons.forward_10), onPressed: onForward),
                IconButton(icon: Icon(Icons.skip_next), onPressed: onNext),
                SizedBox(width: 2),
                Text(formatTime(duration)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
