// lib/services/audio_player_service.dart

// import 'package:just_audio/just_audio.dart';
// import 'package:flutter/material.dart';
//
// class AudioPlayerService {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//
//   // The playlist tracks, managed externally, can be set here
//   List<String> _playlist = [];
//   int _currentTrackIndex = 0;
//
//   /// Initialize the audio player with a playlist.
//   void setPlaylist(List<String> trackUrls, {int startIndex = 0}) {
//     _playlist = trackUrls;
//     _currentTrackIndex = startIndex;
//   }
//
//   /// Plays the audio from a given URL.
//   Future<void> play(String url) async {
//     try {
//       await _audioPlayer.setUrl(url);
//       _audioPlayer.play();
//       // Listen for track completion to auto-play next track.
//       _audioPlayer.playerStateStream.listen((state) {
//         if (state.processingState == ProcessingState.completed) {
//           playNextTrack();
//         }
//       });
//     } catch (e) {
//       debugPrint('Error playing audio: $e');
//     }
//   }
//
//   /// Pauses the current playback.
//   Future<void> pause() async {
//     await _audioPlayer.pause();
//   }
//
//   /// Seeks forward by a given duration.
//   Future<void> forward(Duration offset) async {
//     final currentPosition = await _audioPlayer.position;
//     await _audioPlayer.seek(currentPosition + offset);
//   }
//
//   /// Seeks backward by a given duration.
//   Future<void> rewind(Duration offset) async {
//     final currentPosition = await _audioPlayer.position;
//     Duration newPosition = currentPosition - offset;
//     if (newPosition < Duration.zero) {
//       newPosition = Duration.zero;
//     }
//     await _audioPlayer.seek(newPosition);
//   }
//
//   /// Automatically plays the next track in the playlist.
//   Future<void> playNextTrack() async {
//     if (_playlist.isEmpty) return;
//
//     _currentTrackIndex = (_currentTrackIndex + 1) % _playlist.length;
//     final nextUrl = _playlist[_currentTrackIndex];
//     await play(nextUrl);
//   }
//
//   /// Resumes playback from a given URL and position.
//   Future<void> resume(String url, Duration lastPosition) async {
//     try {
//       await _audioPlayer.setUrl(url);
//       await _audioPlayer.seek(lastPosition);
//       _audioPlayer.play();
//     } catch (e) {
//       debugPrint('Error resuming audio: $e');
//     }
//   }
//
//   /// Exposes the current position stream for UI updates.
//   Stream<Duration> get positionStream => _audioPlayer.positionStream;
//
//   /// Exposes the current playback state.
//   Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
//
//   /// Dispose of the audio player when it's no longer needed.
//   void dispose() {
//     _audioPlayer.dispose();
//   }
// }

// import 'dart:async';
//
// import 'package:audio_streaming_app/helpers/app_helpers.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:rxdart/rxdart.dart';
//
// class AudioPlayerService {
//   final AudioPlayer _player = AudioPlayer();
//   Stream<int?> get currentIndexStream => _player.currentIndexStream;
//   String? _loadedPlaylistId;
//   bool get isReady =>
//       _player.playing ||
//       _player.playerState.processingState != ProcessingState.idle;
//
//   bool isPlaylistLoaded(String playlistId) => _loadedPlaylistId == playlistId;
//
//   /// Loads the given list of URLs into a playlist
//   Future<void> setPlaylist(List<String> urls,
//       {int startIndex = 0, String? playlistId}) async {
//     final playlist = ConcatenatingAudioSource(
//       children: urls.map((url) => AudioSource.uri(Uri.parse(url))).toList(),
//     );
//     try {
//       // Pass preload: false so it doesn’t block on network
//       await _player.setAudioSource(playlist, initialIndex: startIndex);
//       _loadedPlaylistId = playlistId;
//     } on TimeoutException catch (_) {
//       // Let the caller know it failed
//       //throw Exception("Network timeout while loading audio. Please try again.");
//       Helpers.showToast(
//           "Network timeout while loading audio. Please try again.");
//     }
//   }
//
//   /// Plays the current track
//   Future<void> play() => _player.play();
//
//   /// Pauses playback
//   Future<void> pause() => _player.pause();
//
//   /// Plays a specific track from a URL (outside the current playlist)
//   Future<void> playUrl(String url) async {
//     await _player.setUrl(url);
//     await _player.play();
//   }
//
//   /// Seek to a specific time
//   Future<void> seek(Duration position) => _player.seek(position);
//
//   /// Skip to next
//   Future<void> skipToNext() => _player.seekToNext();
//
//   /// Skip to previous
//   Future<void> skipToPrevious() => _player.seekToPrevious();
//
//   /// Cleanup
//   void dispose() => _player.dispose();
//
//   /// Streams
//   Stream<Duration> get positionStream => _player.positionStream;
//   Stream<Duration?> get durationStream => _player.durationStream;
//   Stream<PlayerState> get playerStateStream => _player.playerStateStream;
//
//   /// Fires when a track completes
//   Stream<void> get completionStream => _player.playerStateStream
//       .where((state) =>
//           state.processingState == ProcessingState.completed && !state.playing)
//       .map((_) => null);
//
//   /// Jump to a specific index in the loaded playlist
//   Future<void> skipToIndex(int index) {
//     // seek(position, index: ...) seeks to start of the given item
//     return _player.seek(Duration.zero, index: index);
//   }
// }

import 'package:audio_service/audio_service.dart';
import 'package:divine_stream/app/app.locator.dart';
import 'package:divine_stream/models/audio_file.dart';
import 'package:divine_stream/services/audio_handler_impl_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked_annotations.dart';

@LazySingleton()
class AudioPlayerService {
  final AudioHandler _handler = locator<AudioHandler>();

  List<MediaItem> _mediaItems = [];

  // Track the last‐loaded playlist ID. Set this in setPlaylist().
  String? _loadedPlaylistId;

  /// Returns true if setPlaylist(...) was already called with this same ID
  bool isPlaylistLoaded(String id) => _loadedPlaylistId == id;

  /// Returns true if the handler has actually loaded a playlist and is ready
  bool get isReady {
    // For simplicity, treat “ready” as “we have at least one MediaItem and player isn’t idle”
    // You could also inspect handler.playbackState.processingState if you expose it.
    return _loadedPlaylistId != null;
  }

  /// Expose just_audio’s processingState via AudioHandlerImplService
  Stream<ProcessingState> get processingStateStream =>
      (_handler as AudioHandlerImplService).processingStateStream;

  // Load and prepare a playlist from a list of audio URLs
  Future<void> setPlaylist(List<AudioFile> audioFiles,
      {int startIndex = 0}) async {
    // Create media items with metadata
    _mediaItems = audioFiles.map((file) {
      return MediaItem(
        id: file.url,
        title: file.name, // ✅ Use real name from AudioFile
        artist: 'Streaming Hymns',
        album: 'Imported Playlist',
        duration: Duration.zero, // optional if not known
        // artUri: optional artwork per track if needed
      );
    }).toList();

    // Load into AudioHandlerImpl
    await (_handler as dynamic)
        .loadPlaylist(_mediaItems); // casting to call custom method

    // Seek to the first track
    await _handler.skipToQueueItem(startIndex);

    //await _handler.play(); // this line starts playback

    // Now that it’s loaded, remember which playlist is active:
    _loadedPlaylistId = "playlist‐${audioFiles.hashCode}";
  }

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> stop() => _handler.stop();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> skipToIndex(int index) => _handler.skipToQueueItem(index);
  Future<void> playNext() => _handler.skipToNext();
  Future<void> playPrevious() => _handler.skipToPrevious();

  /// Streams for UI bindings
  Stream<PlaybackState> get playbackStateStream => _handler.playbackState;
  Stream<MediaItem?> get mediaItemStream => _handler.mediaItem;

  /// Extracted player state: playing or not
  Stream<bool> get playerStateStream =>
      _handler.playbackState.map((state) => state.playing);

  Stream<Duration> get positionStream =>
      _handler.playbackState.map((s) => s.updatePosition ?? Duration.zero);

  // Stream<Duration> get durationStream => mediaItemStream.map(
  //       (item) => item?.duration ?? Duration.zero,
  // );
  Stream<Duration> get durationStream => (_handler as AudioHandlerImplService)
      .durationStream
      .map((d) => d ?? Duration.zero);

  Stream<int?> get currentIndexStream => mediaItemStream
      .map((item) => _mediaItems.indexWhere((e) => e.id == item?.id));

// bool get isReady => true; // No-op for now; could add checks later
// bool isPlaylistLoaded(String id) => true; // Could store ID if needed
}
