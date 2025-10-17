import 'dart:developer';

import 'package:divine_stream/app/app.locator.dart';
import 'package:divine_stream/app/app.router.dart';
import 'package:divine_stream/helpers/app_helpers.dart';
import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/models/parent_folder_group.dart';
import 'package:divine_stream/services/connectivity_service.dart';
import 'package:divine_stream/services/drive_permission_service.dart';
import 'package:divine_stream/services/playlist_service.dart';
import 'package:divine_stream/utils/sort_audio_files.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {
  final PlaylistService _playlistService = locator<PlaylistService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final ConnectivityService _connectivityService =
      locator<ConnectivityService>();
  final DrivePermissionService _drivePermissionService =
      locator<DrivePermissionService>();

  List<Playlist> playlists = [];

  /// Playlists whose `parentFolderId` is null are treated as standalone
  /// (no grouping UI).
  List<Playlist> get standalonePlaylists {
    final items = playlists
        .where((playlist) => playlist.parentFolderId == null)
        .toList()
      ..sort((a, b) => numericAwareNameCompare(a.name, b.name));
    return items;
  }

  /// Any playlist with a `parentFolderId` joins a group tile that represents the parent folder.
  List<ParentFolderGroup> get parentFolderGroups {
    final grouped = <String, ParentFolderGroup>{};

    for (final playlist in playlists) {
      final parentId = playlist.parentFolderId;
      if (parentId == null) continue;

      final existingGroup = grouped[parentId];
      if (existingGroup == null) {
        grouped[parentId] = ParentFolderGroup(
          id: parentId,
          name: playlist.parentFolderName ?? 'Folder',
          playlists: [playlist],
        );
      } else {
        existingGroup.playlists.add(playlist);
      }
    }

    for (final group in grouped.values) {
      group.playlists.sort((a, b) => numericAwareNameCompare(a.name, b.name));
    }

    final groups = grouped.values.toList()
      ..sort((a, b) => numericAwareNameCompare(a.name, b.name));
    return groups;
  }

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
    // Quick exit when the device reports no connection so we avoid Drive errors.
    final online = await _connectivityService.ensureConnection();
    if (!online) {
      setBusy(false);
      return;
    }
    try {
      final updated = await _playlistService.refreshAll();
      playlists = updated;
      notifyListeners();
      Helpers.showToast("Playlists refreshed", backgroundColor: Colors.green);
    } catch (e) {
      log(e.toString());
      Helpers.showToast(
          "Error refreshing playlists: ${Helpers.shorten(e.toString())}");
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
    // Drive imports are network-bound; surface a friendly toast if offline.
    final online = await _connectivityService.ensureConnection();
    if (!online) {
      setBusy(false);
      return;
    }
    // Stop early when the folder is still private so we surface a specific
    // sharing hint instead of a generic Drive failure.
    final canReadFolder =
        await _drivePermissionService.ensureFolderAccess(folderId);
    if (!canReadFolder) {
      setBusy(false);
      return;
    }
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
    final lastPlayedId = _playlistService.getLastPlayedTrackId(playlist.id);
    final playlistWithMarker =
        playlist.copyWith(lastPlayedTrackId: lastPlayedId);

    _navigationService.navigateTo(
      Routes.playlistView,
      arguments: PlaylistViewArguments(playlist: playlistWithMarker),
    );
  }

  /// Opens the second-level page that lists the folder's child playlists.
  void openParentFolder(ParentFolderGroup group) {
    _navigationService.navigateTo(
      Routes.folderPlaylistsView,
      arguments: FolderPlaylistsViewArguments(group: group),
    );
  }

  /// Delete playlist after user confirms via platform-specific dialog.
  Future<bool> deletePlaylist(Playlist playlist) async {
    final context = StackedService.navigatorKey?.currentContext;
    if (context == null) return false;

    final confirmed = await Helpers.showPlatformConfirmation(
      context: context,
      title: 'Delete Playlist',
      message: 'Remove "${playlist.name}" from the app?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );

    if (!confirmed) {
      return false;
    }

    try {
      await _playlistService.deletePlaylist(playlist.id);
      playlists =
          playlists.where((existing) => existing.id != playlist.id).toList();
      notifyListeners();

      Helpers.showToast(
        'Playlist deleted',
        backgroundColor: Colors.green,
      );
      return true;
    } catch (e) {
      Helpers.showToast(
        'Delete failed: ${Helpers.shorten(e.toString())}',
      );
      return false;
    }
  }
}
