import 'dart:developer';

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

  List<Playlist> playlists = [];

  /// Initializes the home screen.
  /// - Loads cached playlists (if any) and then refreshes them from Google Drive.
  Future<void> initialize() async {
    setBusy(true);
    // Load cached playlists for a quick UI update.
    playlists = _playlistService.getCachedPlaylists();
    notifyListeners();

    setBusy(false);
  }


  /// Refreshes all playlists (re-syncs from Google Drive)
  Future<void> refreshAllPlaylists() async {
    log("\n in refreshAllPlaylists\n ");
    setBusy(true);
    try {
      final updated = await _playlistService.refreshAll();
      playlists = updated;
      notifyListeners();
      Helpers.showToast("Playlists refreshed", backgroundColor: Colors.green);
    } catch (e) {
      log(e.toString());
      Helpers.showToast("Error refreshing playlists: ${Helpers.shorten(e.toString())}");

    }
    setBusy(false);
  }

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
    // Pull only the persisted last-played marker so we don't lose the fresh
    // in-memory playlist (its audio URLs are up to date, whereas the cached
    // copy may still contain stale links).
    final lastPlayedId =
        _playlistService.getLastPlayedTrackId(playlist.id);
    final playlistWithMarker =
        playlist.copyWith(lastPlayedTrackId: lastPlayedId);

    _navigationService.navigateTo(
      Routes.playlistView,
      arguments: PlaylistViewArguments(playlist: playlistWithMarker),
    );
  }
}
