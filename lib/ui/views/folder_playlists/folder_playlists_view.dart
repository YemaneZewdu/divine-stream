import 'package:divine_stream/models/parent_folder_group.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'folder_playlists_viewmodel.dart';

/// Lists the playlists that belong to an imported parent folder.
class FolderPlaylistsView extends StackedView<FolderPlaylistsViewModel> {
  final ParentFolderGroup group;

  const FolderPlaylistsView({Key? key, required this.group}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    FolderPlaylistsViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
      ),
      body: ListView.builder(
        itemCount: viewModel.playlists.length,
        itemBuilder: (context, index) {
          final playlist = viewModel.playlists[index];
          return ListTile(
            title: Text(playlist.name),
            subtitle: Text("${playlist.audioFiles.length} audio files"),
            onTap: () => viewModel.openPlaylist(playlist),
          );
        },
      ),
    );
  }

  @override
  FolderPlaylistsViewModel viewModelBuilder(BuildContext context) {
    return FolderPlaylistsViewModel(group: group);
  }
}
