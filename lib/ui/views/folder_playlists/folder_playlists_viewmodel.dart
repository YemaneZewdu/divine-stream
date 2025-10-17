import 'package:divine_stream/app/app.locator.dart';
import 'package:divine_stream/app/app.router.dart';
import 'package:divine_stream/models/parent_folder_group.dart';
import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/services/playlist_service.dart';
import 'package:divine_stream/utils/sort_audio_files.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// Hosts navigation for the grouped folder detail page.
class FolderPlaylistsViewModel extends BaseViewModel {
  final ParentFolderGroup group;

  final NavigationService _navigationService = locator<NavigationService>();
  final PlaylistService _playlistService = locator<PlaylistService>();

  FolderPlaylistsViewModel({required this.group});

  /// Create a sorted copy so the UI mirrors the home screen ordering.
  List<Playlist> get playlists {
    final sorted = List<Playlist>.from(group.playlists)
      ..sort((a, b) => numericAwareNameCompare(a.name, b.name));
    return sorted;
  }

  /// Reuse the playlist opening flow so we keep the last-played marker intact.
  void openPlaylist(Playlist playlist) {
    final lastPlayedId = _playlistService.getLastPlayedTrackId(playlist.id);
    final playlistWithMarker =
        playlist.copyWith(lastPlayedTrackId: lastPlayedId);

    _navigationService.navigateTo(
      Routes.playlistView,
      arguments: PlaylistViewArguments(playlist: playlistWithMarker),
    );
  }
}
