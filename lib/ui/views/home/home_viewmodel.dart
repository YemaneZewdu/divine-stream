import 'dart:developer';

import 'package:divine_stream/app/app.locator.dart';
import 'package:divine_stream/app/app.router.dart';
import 'package:divine_stream/helpers/app_helpers.dart';
import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/models/parent_folder_group.dart';
import 'package:divine_stream/services/connectivity_service.dart';
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
  List<Playlist> playlists = [];

  /// Any manifest without `parentFolderId` represents a top-level folder,
  ///  so we surface it directly on the home list.
  List<Playlist> get standalonePlaylists {
    final items = playlists
        .where((playlist) => playlist.parentFolderId == null)
        .toList()
      ..sort((a, b) => numericAwareNameCompare(a.name, b.name));
    return items;
  }

  ///  Manifests tagged with `parentFolderId` belong under a grouped parent
  ///  tile—this keeps sub-folders off the root screen.
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

  ///  Kick off with cached data for instant paint, then sync against Firebase.
  Future<void> initialize() async {
    setBusy(true);
    // Load cached playlists for a quick UI update.
    playlists = _playlistService.getCachedPlaylists();
    notifyListeners();

    setBusy(false);
    await syncFromFirebase();
  }

  //  Pull a fresh snapshot from Firestore and cache the result locally.
  Future<void> refreshAllPlaylists() async {
    setBusy(true);
    // Bail out early if we have no connection;
    // Firestore sync would fail anyway.
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

  Future<void> syncFromFirebase() async {
    setBusy(true);
    // Firebase now acts as the single source of truth—no Drive dialog needed.
    final online = await _connectivityService.ensureConnection();
    if (!online) {
      setBusy(false);
      return;
    }
    try {
      final newPlaylists =
          await _playlistService.importNestedPlaylists('firebase');
      playlists = newPlaylists;
      notifyListeners();
      Helpers.showToast("Playlist(s) synced!", backgroundColor: Colors.green);
    } catch (e) {
      Helpers.showToast("Sync failed: ${Helpers.shorten(e.toString())}");
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
