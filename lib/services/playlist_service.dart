import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/services/firebase_playlist_loader.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

class PlaylistService {
  final FirebasePlaylistLoader _firebasePlaylistLoader;
  final Box _box = Hive.box('playlistsBox');

  // Resolve the Firebase loader via locator so generated code can keep
  // requesting this service without threading dependencies around.
  PlaylistService({FirebasePlaylistLoader? firebasePlaylistLoader})
      : _firebasePlaylistLoader =
            firebasePlaylistLoader ?? GetIt.instance<FirebasePlaylistLoader>();

  /// Retrieve playlists from Hive so the UI renders instantly offline.
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

  /// Persist the latest manifest snapshot for offline rehydration.
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

  /// Persist the most recently played track so reopening highlights it.
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

  /// Imports the entire manifest from Firebase; the root id is ignored now.
  Future<List<Playlist>> importNestedPlaylists(String rootFolderId) async {
    // The Firebase manifest already contains the full playlist list, so the
    // `rootFolderId` argument is ignored and we fetch everything instead.
    final firebasePlaylists = await _firebasePlaylistLoader.fetchPlaylists();
    return await _mergeAndPersist(firebasePlaylists);
  }

  /// Force-refresh playlists by rebuilding them from the manifest.
  Future<List<Playlist>> refreshAll() async {
    final firebasePlaylists = await _firebasePlaylistLoader.fetchPlaylists();
    return await _mergeAndPersist(firebasePlaylists);
  }

  /// Remove a playlist (plus cached metadata) from local storage.
  Future<void> deletePlaylist(String playlistId) async {
    final playlists = getCachedPlaylists();
    final updated =
        playlists.where((playlist) => playlist.id != playlistId).toList();

    if (updated.length == playlists.length) {
      return; // Nothing to delete; keep storage untouched.
    }

    await _savePlaylists(updated);
  }

  Future<List<Playlist>> _mergeAndPersist(List<Playlist> incoming) async {
    final current = getCachedPlaylists();

    // Carry over persisted metadata (e.g. last played track) before replacing the cache.
    final enriched = incoming.map((playlist) {
      final existing = current.firstWhere(
        (cached) => cached.id == playlist.id,
        orElse: Playlist.empty,
      );
      return playlist.copyWith(
        lastPlayedTrackId: existing.lastPlayedTrackId,
      );
    }).toList();

    // Merge by id so we ignore duplicates that may still live in the cache.
    final merged = <String, Playlist>{
      for (final playlist in current) playlist.id: playlist,
      for (final playlist in enriched) playlist.id: playlist,
    };

    final mergedList = merged.values.toList();
    await _savePlaylists(mergedList);
    return mergedList;
  }
}
