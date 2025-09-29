import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/services/google_drive_service.dart';
import 'package:divine_stream/utils/sort_audio_files.dart';
import 'package:hive/hive.dart';

import '../models/audio_file.dart';

class PlaylistService {
  final GoogleDriveService _googleDriveService;
  final Box _box = Hive.box('playlistsBox');

  PlaylistService(this._googleDriveService);

  /// Retrieve playlists from Hive (offline mode)
  List<Playlist> getCachedPlaylists() {
    final List<dynamic>? raw = _box.get('playlists');
    if (raw == null) return [];

    return raw.map((entry) {
      // Safely cast each entry to Map<String, dynamic>
      final Map<String, dynamic> json = entry is Map<String, dynamic>
          ? entry
          : Map<String, dynamic>.from(entry as Map);
      return Playlist.fromJson(json);
    }).toList();
  }

  /// Save playlists to Hive
  Future<void> _savePlaylists(List<Playlist> playlists) async {
    List<Map<String, dynamic>> jsonData =
        playlists.map((playlist) => playlist.toJson()).toList();
    await _box.put('playlists', jsonData);
  }

  /// Returns the cached track ID we should resume from, if any.
  String? getLastPlayedTrackId(String playlistId) {
    return getCachedPlaylists()
        .firstWhere((p) => p.id == playlistId, orElse: Playlist.empty)
        .lastPlayedTrackId;
  }

  /// Persists the most recently played track for the given playlist.
  Future<void> setLastPlayedTrack(String playlistId, String trackId) async {
    final playlists = getCachedPlaylists();
    var didUpdate = false;
    final updated = playlists.map((playlist) {
      if (playlist.id != playlistId) return playlist;
      didUpdate = true;
      return playlist.copyWith(lastPlayedTrackId: trackId);
    }).toList();

    if (didUpdate) {
      await _savePlaylists(updated);
    }
  }

  /// Imports all subfolders with audio files under a root folder
  Future<List<Playlist>> importNestedPlaylists(String rootFolderId) async {
    final nestedPlaylists =
        await _googleDriveService.scanNestedFolders(rootFolderId);
    final current = getCachedPlaylists();

    // Preserve last-played markers when we already have this playlist cached.
    final enriched = nestedPlaylists.map((playlist) {
      final existing = current.firstWhere(
        (cached) => cached.id == playlist.id,
        orElse: Playlist.empty,
      );
      return playlist.copyWith(
        lastPlayedTrackId: existing.lastPlayedTrackId,
      );
    }).toList();

    final merged = <String, Playlist>{
      for (final playlist in current) playlist.id: playlist,
      for (final playlist in enriched) playlist.id: playlist,
    };

    await _savePlaylists(merged.values.toList());
    return enriched;
  }

  /// Refreshes all playlists by re-fetching their contents from Drive
  Future<List<Playlist>> refreshAll() async {
    final current = getCachedPlaylists();
    final refreshed = <Playlist>[];

    for (final playlist in current) {
      final rawFiles = await _googleDriveService.fetchAudioFiles(playlist.id);

      // 1 Decode into AudioFile
      final files = rawFiles
          .map((m) => AudioFile.fromJson(m))
          .toList();

      // 2 Sort with your comparator
      files.sort(audioFileComparator);

      // 3 Build the updated Playlist
      refreshed.add(playlist.copyWith(audioFiles: files));
    }

    await _savePlaylists(refreshed);
    return refreshed;
  }
}
