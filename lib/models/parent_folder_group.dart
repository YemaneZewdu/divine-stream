import 'package:divine_stream/models/playlist.dart';

///  Lightweight wrapper for the parent folder tile rendered
///  on the home screen.
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
