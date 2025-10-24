import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:divine_stream/models/audio_file.dart';
import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/utils/sort_audio_files.dart';

// Fetch playlist manifests produced by the Cloud Function and adapt them
// to the legacy `Playlist` shape so the rest of the app keeps working.
class FirebasePlaylistLoader {
  final FirebaseFirestore _firestore;

  FirebasePlaylistLoader({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Playlist>> fetchPlaylists() async {
    final snapshot = await _firestore.collection('manifests').get();

    final playlists = <Playlist>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rawTracks = data['tracks'] as List<dynamic>?;
      if (rawTracks == null || rawTracks.isEmpty) {
        continue;
      }

      final tracks = rawTracks.map((raw) {
        final track = raw as Map<String, dynamic>;
        final rawName = track['name'] as String? ?? '';
        final displayName = _stripExtension(rawName);
        return AudioFile(
          id: track['id'] as String? ?? '',
          title: displayName,
          name: displayName,
          url: track['url'] as String? ?? '',
        );
      }).toList()
        ..sort(audioFileComparator);

      final playlistName = data['name'] as String? ?? doc.id;
      final pathValue = data['path'] as String? ?? '';
      var parentId = data['parentId'] as String?;
      var parentName = data['parentName'] as String?;

      // Firestore manifests mark nested folders with `parentId`; fall back
      // to the path prefix so we can still identify grouped playlists even
      // if older documents are missing the explicit fields.
      if (parentId == null && pathValue.contains('/')) {
        parentId = pathValue.split('/').first;
        parentName ??= parentId;
      }

      playlists.add(
        Playlist(
          id: doc.id,
          name: playlistName,
          audioFiles: tracks,
          parentFolderId: parentId,
          parentFolderName: parentName,
        ),
      );
    }

    playlists.sort((a, b) => numericAwareNameCompare(a.name, b.name));
    return playlists;
  }
}

String _stripExtension(String name) {
  // Normalise track titles by removing the file suffix before the UI sees them.
  final index = name.lastIndexOf('.');
  if (index <= 0) {
    return name;
  }
  return name.substring(0, index);
}
