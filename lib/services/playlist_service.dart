import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/services/google_drive_service.dart';
import 'package:hive/hive.dart';

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

}

