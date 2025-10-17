import 'package:divine_stream/models/parent_folder_group.dart';
import 'package:divine_stream/models/playlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:stacked/stacked.dart';
import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      onViewModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) {
        return Scaffold(
            appBar: AppBar(
              title: Text("Divine Audio Streaming"),
              actions: [
                IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () => viewModel.refreshAllPlaylists()),
              ],
            ),
            body: viewModel.isBusy
                ? Center(child: CircularProgressIndicator())
                : (viewModel.parentFolderGroups.isEmpty &&
                        viewModel.standalonePlaylists.isEmpty)
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "No playlists yet.\nTap + to import from Google Drive.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    : _HomeListView(viewModel: viewModel),
            floatingActionButton: FloatingActionButton(
              onPressed: viewModel.importFromGoogleDriveFolder,
              child: Icon(Icons.add),
            ));
      },
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();

  @override
  void onViewModelReady(HomeViewModel viewModel) {
    viewModel.initialize();
    super.onViewModelReady(viewModel);
  }
}

/// Builds a mixed list where grouped folders and standalone playlists
/// share one feed.
class _HomeListView extends StatelessWidget {
  final HomeViewModel viewModel;

  const _HomeListView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final folderGroups = viewModel.parentFolderGroups;
    final standalonePlaylists = viewModel.standalonePlaylists;

    final entries = <_HomeListEntry>[
      for (final group in folderGroups) _HomeListEntry.group(group),
      for (final playlist in standalonePlaylists)
        _HomeListEntry.playlist(playlist),
    ];

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.group != null) {
          final ParentFolderGroup group = entry.group!;
          return ListTile(
            key: ValueKey('group-${group.id}'),
            title: Text(group.name),
            subtitle: Text('${group.playlists.length} playlists'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => viewModel.openParentFolder(group),
          );
        }

        final playlist = entry.playlist!;
        return SwipeActionCell(
          key: ValueKey(playlist.id),
          trailingActions: [
            SwipeAction(
              // Use destructive styling so the intent is clear to the user.
              color: Colors.red,
              icon: Icon(Icons.delete, color: Colors.white),
              onTap: (handler) async {
                final removed = await viewModel.deletePlaylist(playlist);
                // Close the cell; pass true only when we actually removed it.
                await handler(removed);
              },
            ),
          ],
          child: ListTile(
            title: Text(playlist.name),
            subtitle: Text('${playlist.audioFiles.length} audio files'),
            onTap: () => viewModel.openPlaylist(playlist),
          ),
        );
      },
    );
  }
}

class _HomeListEntry {
  final ParentFolderGroup? group;
  final Playlist? playlist;

  _HomeListEntry._({this.group, this.playlist});

  factory _HomeListEntry.group(ParentFolderGroup group) {
    return _HomeListEntry._(group: group);
  }

  factory _HomeListEntry.playlist(Playlist playlist) {
    return _HomeListEntry._(playlist: playlist);
  }
}
