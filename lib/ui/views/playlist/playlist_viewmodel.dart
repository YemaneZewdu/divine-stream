import 'package:divine_stream/app/app.locator.dart';
import 'package:divine_stream/helpers/app_helpers.dart';
import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/services/audio_player_service.dart';
import 'package:divine_stream/services/playlist_service.dart';
import 'package:divine_stream/services/connectivity_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked.dart';

import '../../../models/audio_file.dart';

class PlaylistViewModel extends BaseViewModel {
  final AudioPlayerService _audioService = locator<AudioPlayerService>();
  final PlaylistService _playlistService = locator<PlaylistService>();
  final ConnectivityService _connectivityService =
      locator<ConnectivityService>();

  late Playlist playlist;
  List<AudioFile> tracks = [];
  int currentIndex = 0;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool _isSeeking = false;
  Duration _tempSeekPos = Duration.zero;
  Duration get effectivePosition => _isSeeking ? _tempSeekPos : position;
  // Store the first non-zero duration and ignore later zeros
  Duration _lastNonZeroDuration = Duration.zero;

  void onSeekStart() {
    _isSeeking = true;
  }

  void onSeekEnd(Duration newPosition) async {
    _isSeeking = false;
    _tempSeekPos = Duration.zero;
    await _audioService.seek(newPosition);
  }

  void onSeekUpdate(Duration newPos) {
    _tempSeekPos = newPos;
    notifyListeners();
  }

  /// Call this from the view’s onModelReady, passing in the routed playlist.
  Future<void> init(Playlist p) async {
    playlist = p;
    tracks = p.audioFiles;
    // Default to the cached last played track; fall back to the first one.
    currentIndex = p.lastPlayedIndex() ?? 0;
    notifyListeners(); // show UI immediately

    // Listen for processing state to update isBusy:
    _audioService.processingStateStream.listen((state) {
      // Show spinner while loading or buffering, hide otherwise
      final busy = state == ProcessingState.loading ||
          state == ProcessingState.buffering;
      if (isBusy != busy) {
        setBusy(busy);
        notifyListeners();
      }
    });

    // ✅ If the playlist is already loaded AND the player is ready, skip reloading
    if (_audioService.isPlaylistLoaded(p.id) && _audioService.isReady) {
      _subscribeToStreams();
      // await _audioService.play();
      return;
    }

    setBusy(true);

    // Loading audio from Firebase still requires connectivity; abort cleanly if offline.
    final online = await _connectivityService.ensureConnection();
    if (!online) {
      setBusy(false);
      return;
    }

    // ✅ Prepare URLs and set the playlist (with error handling)
    try {
      await _audioService.setPlaylist(
        tracks,
        startIndex: currentIndex,
        playlistId: playlist.id, // Preserve playlist identity for cache re-use.
      );
      //await _audioService.play();
    } catch (e) {
      print(e.toString());
      setBusy(false);
      Helpers.showToast("Please try again in playlist vm");
    }

    _subscribeToStreams();

    setBusy(false);
  }

  void _subscribeToStreams() {
    _audioService.playerStateStream.listen((playing) {
      //print('\n📡 ViewModel received playing: $playing');
      isPlaying = playing;
      notifyListeners();
    });

    _audioService.positionStream.listen((pos) {
      position = pos;
      notifyListeners();
    });

    // _audioService.durationStream.listen((dur) {
    //   if (dur != null) {
    //     duration = dur;
    //     notifyListeners();
    //   }
    // });
    _audioService.durationStream.listen((dur) {
      final shouldUpdate =
          dur > Duration.zero || _lastNonZeroDuration == Duration.zero;

      if (shouldUpdate) {
        _lastNonZeroDuration = dur;
        duration = dur; // ← your existing field
        notifyListeners();
      }
    });

    _audioService.currentIndexStream.listen((newIndex) {
      if (newIndex != null) {
        currentIndex = newIndex;
        if (newIndex >= 0 && newIndex < tracks.length) {
          final trackId = tracks[newIndex].id;
          // Persist the new position so reopening the playlist resumes here.
          _playlistService.setLastPlayedTrack(playlist.id, trackId);
          playlist = playlist.copyWith(lastPlayedTrackId: trackId);
        }
        notifyListeners();
      }
    });
  }

  Future<void> playTrack(int index) async {
    // Do not attempt to pull a new track without connectivity.
    final online = await _connectivityService.ensureConnection();
    if (!online) {
      return;
    }
    final track = tracks[index];
    await _audioService.prepareTrack(index);
    currentIndex = index;
    notifyListeners();
    // Jump the playlist directly:
    await _audioService.skipToIndex(index);
    final trackId = track.id;
    await _playlistService.setLastPlayedTrack(playlist.id, trackId);
    playlist = playlist.copyWith(lastPlayedTrackId: trackId);
    //await _audioService.play();
  }

  // Future<void> togglePlayPause() async {
  //   if (isPlaying) {
  //     await _audioService.pause();
  //   } else {
  //     await _audioService.play();
  //   }
  // }
  Future<void> togglePlayPause() async {
    // 1. Flip the local flag first so the UI reacts instantly.
    final bool wasPlaying = isPlaying;
    isPlaying = !wasPlaying;
    notifyListeners();

    try {
      // 2. Forward the real command.
      if (wasPlaying) {
        await _audioService.pause();
      } else {
        final online = await _connectivityService.ensureConnection();
        if (!online) {
          // Connectivity check already surfaced the toast; keep UI in sync.
          isPlaying = wasPlaying;
          notifyListeners();
          return;
        }
        await _audioService.play();
      }
    } catch (e) {
      // 3. Roll back on error to avoid a misleading state.
      isPlaying = wasPlaying;
      notifyListeners();
    }
  }

  Future<void> seekForward() =>
      _audioService.seek(position + Duration(seconds: 10));

  Future<void> seekBackward() =>
      _audioService.seek(position - Duration(seconds: 10));

  Future<void> playNext() async {
    // Next/previous will stream new media; guard against offline usage.
    final online = await _connectivityService.ensureConnection();
    if (!online) {
      return;
    }
    if (currentIndex < tracks.length - 1) {
      currentIndex++;
      notifyListeners();
      await playTrack(currentIndex);
    }
  }

  Future<void> playPrevious() async {
    // Next/previous will stream new media; guard against offline usage.
    final online = await _connectivityService.ensureConnection();
    if (!online) {
      return;
    }
    if (currentIndex > 0) {
      currentIndex--;
      notifyListeners();
      await playTrack(currentIndex);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> seekTo(Duration pos) async {
    await _audioService.seek(pos);
  }
}
