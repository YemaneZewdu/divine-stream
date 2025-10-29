import 'dart:math' as math;

import 'package:divine_stream/models/playlist.dart';
import 'package:divine_stream/ui/playback_controls/playback_controls.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:stacked/stacked.dart';

import 'playlist_viewmodel.dart';

class PlaylistView extends StatefulWidget {
  final Playlist playlist;

  const PlaylistView({super.key, required this.playlist});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener = ItemPositionsListener.create();

  int? _lastAutoScrollIndex;
  bool _hasJumpedToInitial = false;
  int _visibleMin = 0;
  int _visibleMax = 0;

  @override
  void initState() {
    super.initState();
    // [new] Track which rows are visible so we only scroll
    // when the active track leaves the viewport.
    _positionsListener.itemPositions.addListener(_updateVisibleWindow);
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_updateVisibleWindow);
    super.dispose();
  }

  void _updateVisibleWindow() {
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) {
      return;
    }

    final indices = positions.map((pos) => pos.index);
    _visibleMin = indices.reduce(math.min);
    _visibleMax = indices.reduce(math.max);
  }

  void _maybeScrollTo(int index, int itemCount, {bool force = false}) {
    if (index < 0 || index >= itemCount) {
      return;
    }

    if (!_scrollController.isAttached) {
      return;
    }

    if (!force && _lastAutoScrollIndex == index) {
      return;
    }

    // [new] Let the track drift slightly before we pull it back into view.
    const buffer = 1;
    final withinViewport =
        index >= (_visibleMin - buffer) && index <= (_visibleMax + buffer);

    if (withinViewport && !force) {
      _lastAutoScrollIndex = index;
      return;
    }

    if (force) {
      // [new] Package asserts against zero-duration animations;
      // use jumpTo for the initial snap.
      _scrollController.jumpTo(
        index: index,
        alignment: 0.3,
      );
    } else {
      _scrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.3, // [new] Keep the active track near the top while leaving context above it.
      );
    }
    _lastAutoScrollIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PlaylistViewModel>.reactive(
      viewModelBuilder: () => PlaylistViewModel(),
      onViewModelReady: (vm) => vm.init(widget.playlist),
      builder: (context, vm, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (vm.tracks.isEmpty) {
            return;
          }

          if (!_hasJumpedToInitial) {
            _maybeScrollTo(vm.currentIndex, vm.tracks.length, force: true);
            _hasJumpedToInitial = true;
          } else {
            _maybeScrollTo(vm.currentIndex, vm.tracks.length);
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.playlist.name, style: const TextStyle(fontSize: 18)),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
            child: Column(
              children: [
                Expanded(
                  child: ScrollablePositionedList.builder(
                    itemCount: vm.tracks.length,
                    itemScrollController: _scrollController,
                    itemPositionsListener: _positionsListener,
                    itemBuilder: (context, index) {
                      final track = vm.tracks[index];
                      final isActive = index == vm.currentIndex;
                      final title = track.title.isNotEmpty
                          ? track.title
                          : track.name; // [new] Fall back gracefully if older caches miss `title`.
                      return ListTile(
                        title: Text(title),
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
                PlaybackControls(
                  isPlaying: vm.isPlaying,
                  position: vm.position,
                  duration: vm.duration,
                  onPlayPause: vm.togglePlayPause,
                  onForward: vm.seekForward,
                  onRewind: vm.seekBackward,
                  onNext: vm.playNext,
                  onPrevious: vm.playPrevious,
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
