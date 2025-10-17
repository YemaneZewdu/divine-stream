import 'package:divine_stream/models/playlist.dart';

/// Lightweight wrapper that represents the grouped parent folder entry shown on Home.
class ParentFolderGroup {
  final String id;
  final String name;
  final List<Playlist> playlists;

  ParentFolderGroup({
    required this.id,
    required this.name,
    required this.playlists,
  });
}
