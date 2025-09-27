import 'package:divine_stream/app/app.locator.dart';
import 'package:divine_stream/app/app.router.dart';
import 'package:divine_stream/helpers/app_helpers.dart';
import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/services/google_drive_service.dart';
import 'package:divine_stream/services/playlist_service.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {
  final PlaylistService _playlistService = locator<PlaylistService>();
  final GoogleDriveService _googleDriveService = locator<GoogleDriveService>();
  final NavigationService _navigationService = locator<NavigationService>();

  /// Initializes the home screen.
  /// - Loads cached playlists (if any) and then refreshes them from Google Drive.
  Future<void> initialize() async {}

  List<Playlist> playlists = [];

  /// Refreshes all playlists (re-syncs from Google Drive)
  Future<void> refreshAllPlaylists() async {}

  /// Prompts user to paste a folder link and imports it
  Future<void> importFromGoogleDriveFolder() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: StackedService.navigatorKey!.currentContext!,
      builder: (context) => AlertDialog(
        title: Text("Import Playlist"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Paste folder link here"),
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text("Import"),
            onPressed: () => Navigator.of(context).pop(controller.text),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    final folderId = Helpers.extractFolderIdFromUrl(result.trim());
    if (folderId == null) {
      Helpers.showToast(
        "Invalid folder link.",
      );
      return;
    }

    setBusy(true);
    try {
      final newPlaylists =
          await _playlistService.importNestedPlaylists(folderId);
      playlists.addAll(newPlaylists);
      notifyListeners();
      Helpers.showToast("Playlist(s) imported!", backgroundColor: Colors.green);
    } catch (e) {
      Helpers.showToast("Import failed: ${Helpers.shorten(e.toString())}");
    }
    setBusy(false);
  }

  /// Navigates to playlist view
  void openPlaylist(Playlist playlist) {
    _navigationService.navigateTo(
      Routes.playlistView,
      arguments: PlaylistViewArguments(playlist: playlist),
    );
  }
}
