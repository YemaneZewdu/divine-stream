import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {


  /// Initializes the home screen.
  /// - Loads cached playlists (if any) and then refreshes them from Google Drive.
  Future<void> initialize() async {

  }


  /// Refreshes all playlists (re-syncs from Google Drive)
  Future<void> refreshAllPlaylists() async {

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

  }

}
