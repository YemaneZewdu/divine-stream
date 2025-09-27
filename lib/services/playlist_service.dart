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

  /// Imports all subfolders with audio files under a root folder
  Future<List<Playlist>> importNestedPlaylists(String rootFolderId) async {
    final nestedPlaylists =
        await _googleDriveService.scanNestedFolders(rootFolderId);
    final current = getCachedPlaylists();
    final updated = [...current, ...nestedPlaylists];
    await _savePlaylists(updated);
    return nestedPlaylists;
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
      refreshed.add(Playlist(
        id: playlist.id,
        name: playlist.name,
        audioFiles: files,
      ));
    }

    await _savePlaylists(refreshed);
    return refreshed;
  }
}
