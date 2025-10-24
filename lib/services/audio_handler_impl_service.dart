import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:divine_stream/helpers/app_helpers.dart';
import 'package:just_audio/just_audio.dart';

class AudioHandlerImplService extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  List<MediaItem> _mediaItems = [];

  AudioHandlerImplService() {
    _init();
  }

  Future<void> _init() async {
    // 1. Broadcast playback state changes
    _player.playerStateStream.listen(_broadcastState);

    // 2. Broadcast current track metadata
    _player.currentIndexStream.listen((index) {
      if (index != null && index < _mediaItems.length) {
        mediaItem.add(_mediaItems[index]);
      }
    });

    // 3. Broadcast current playback position
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });

    // 4. Keep the now-playing item in sync with duration updates so lock screens
    // show the correct progress bar once just_audio discovers the length.
    _player.durationStream.listen((duration) {
      if (duration == null) return;
      final current = mediaItem.value;
      if (current == null) return;

      mediaItem.add(current.copyWith(duration: duration));
    });

    //  Error handler
    _player.playbackEventStream.listen((event) {},
        onError: (Object error, StackTrace stackTrace) {
      Helpers.showToast('Audio error occurred: $error');
    });
  }

  ///  Seed just_audio with remote URLs first;
  ///  cached swaps will replace them lazily
  Future<void> loadPlaylist(List<MediaItem> items) async {
    _mediaItems = items;
    queue.add(items); // tell the system what’s in the queue

    // DEBUG: print each URL
    for (var item in items) {
      log(' loadPlaylist URL: ${item.id}');
      log('AudioHandler loading ${item.id}');
    }

    final sources =
        items.map((item) => AudioSource.uri(Uri.parse(item.id))).toList();
    _playlist.clear();
    _playlist.addAll(sources);

    log('\n››› Setting audio source');
    await _player.setAudioSource(_playlist);
    mediaItem.add(_mediaItems[0]);
    // Let the caller decide when to start playback so we can seek to the saved
    // track index first; auto-play happens via view model after skipToQueueItem.
  }

  // Swap the underlying audio source for a queue item so we can point at a
  // cached file once it finishes downloading.
  Future<void> swapSourceAt(int index, Uri uri, MediaItem updatedItem) async {
    if (index < 0 || index >= _mediaItems.length) {
      return;
    }

    final wasCurrent = _player.currentIndex == index;

    await _playlist.removeAt(index);
    await _playlist.insert(index, AudioSource.uri(uri));

    _mediaItems[index] = updatedItem;
    queue.add(List<MediaItem>.from(_mediaItems));

    if (wasCurrent) {
      //  Force just_audio to re-open the swapped source so iOS stops
      //  pointing at the removed remote URL.
      await _player.seek(Duration.zero, index: index);
      mediaItem.add(updatedItem);
    } else if (_player.currentIndex == index) {
      mediaItem.add(updatedItem);
    }
  }

  /// Expose the raw processingState from just_audio
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  /// Player Controls
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  /// Skip to specific item
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _mediaItems.length) {
      await _player.seek(Duration.zero, index: index);
    }
  }

  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Future<void> onTaskRemoved() async {
    // Keep the notification and audio session alive when the OS removes the
    // task from recents; this mirrors typical media app behaviour.
    // No-op here, but returning ensures audio_service doesn’t stop playback.
  }

  void _broadcastState(PlayerState state) {
    final isPlaying = state.playing;
    final processingState = state.processingState;

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        isPlaying ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _transformState(processingState),
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  AudioProcessingState _transformState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}
