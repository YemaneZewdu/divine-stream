import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/ui/playback_controls/playback_controls.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'playlist_viewmodel.dart';

class PlaylistView extends StatelessWidget {
  final Playlist playlist;

  const PlaylistView({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PlaylistViewModel>.reactive(
      viewModelBuilder: () => PlaylistViewModel(),
      onViewModelReady: (vm) => vm.init(playlist),
      builder: (context, vm, child) {
        return Scaffold(
          appBar: AppBar(title: Text(playlist.name, style: TextStyle(fontSize: 18))),
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: vm.tracks.length,
                    itemBuilder: (context, index) {
                      final track = vm.tracks[index];
                      final isActive = index == vm.currentIndex;
                      return ListTile(
                        title: Text(track.name),
                        tileColor: isActive
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2)
                            : null,
                        onTap: () => vm.playTrack(index),
                      );
                    },
                  ),
                ),
                //vm.isBusy ?  Center(child: CircularProgressIndicator()) :
                PlaybackControls(
                  isPlaying: vm.isPlaying,
                  position: vm.position,
                  duration: vm.duration,
                  onPlayPause: vm.togglePlayPause,
                  onForward: vm.seekForward,
                  onRewind: vm.seekBackward,
                  onNext: vm.playNext,
                  onPrevious: vm.playPrevious,
                  //onSeek: vm.seekTo,
                  isBusy: vm.isBusy,
                  onSeekStart: vm.onSeekStart,
                  onSeekUpdate: vm.onSeekUpdate,
                  onSeekEnd: vm.onSeekEnd,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
