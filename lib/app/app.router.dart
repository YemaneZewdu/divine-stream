// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:divine_stream/models/parent_folder_group.dart' as _i8;
import 'package:divine_stream/models/playlist.dart' as _i7;
import 'package:divine_stream/ui/views/folder_playlists/folder_playlists_view.dart'
    as _i5;
import 'package:divine_stream/ui/views/home/home_view.dart' as _i2;
import 'package:divine_stream/ui/views/playlist/playlist_view.dart' as _i4;
import 'package:divine_stream/ui/views/startup/startup_view.dart' as _i3;
import 'package:flutter/material.dart' as _i6;
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i9;

class Routes {
  static const homeView = '/home-view';

  static const startupView = '/startup-view';

  static const playlistView = '/playlist-view';

  static const folderPlaylistsView = '/folder-playlists-view';

  static const all = <String>{
    homeView,
    startupView,
    playlistView,
    folderPlaylistsView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(
      Routes.homeView,
      page: _i2.HomeView,
    ),
    _i1.RouteDef(
      Routes.startupView,
      page: _i3.StartupView,
    ),
    _i1.RouteDef(
      Routes.playlistView,
      page: _i4.PlaylistView,
    ),
    _i1.RouteDef(
      Routes.folderPlaylistsView,
      page: _i5.FolderPlaylistsView,
    ),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.HomeView: (data) {
      return _i6.MaterialPageRoute<dynamic>(
        builder: (context) => _i2.HomeView(),
        settings: data,
      );
    },
    _i3.StartupView: (data) {
      return _i6.MaterialPageRoute<dynamic>(
        builder: (context) => const _i3.StartupView(),
        settings: data,
      );
    },
    _i4.PlaylistView: (data) {
      final args = data.getArgs<PlaylistViewArguments>(nullOk: false);
      return _i6.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i4.PlaylistView(key: args.key, playlist: args.playlist),
        settings: data,
      );
    },
    _i5.FolderPlaylistsView: (data) {
      final args = data.getArgs<FolderPlaylistsViewArguments>(nullOk: false);
      return _i6.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i5.FolderPlaylistsView(key: args.key, group: args.group),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class PlaylistViewArguments {
  const PlaylistViewArguments({
    this.key,
    required this.playlist,
  });

  final _i6.Key? key;

  final _i7.Playlist playlist;

  @override
  String toString() {
    return '{"key": "$key", "playlist": "$playlist"}';
  }

  @override
  bool operator ==(covariant PlaylistViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.playlist == playlist;
  }

  @override
  int get hashCode {
    return key.hashCode ^ playlist.hashCode;
  }
}

class FolderPlaylistsViewArguments {
  const FolderPlaylistsViewArguments({
    this.key,
    required this.group,
  });

  final _i6.Key? key;

  final _i8.ParentFolderGroup group;

  @override
  String toString() {
    return '{"key": "$key", "group": "$group"}';
  }

  @override
  bool operator ==(covariant FolderPlaylistsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.group == group;
  }

  @override
  int get hashCode {
    return key.hashCode ^ group.hashCode;
  }
}

extension NavigatorStateExtension on _i9.NavigationService {
  Future<dynamic> navigateToHomeView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.homeView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToStartupView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.startupView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToPlaylistView({
    _i6.Key? key,
    required _i7.Playlist playlist,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.playlistView,
        arguments: PlaylistViewArguments(key: key, playlist: playlist),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToFolderPlaylistsView({
    _i6.Key? key,
    required _i8.ParentFolderGroup group,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.folderPlaylistsView,
        arguments: FolderPlaylistsViewArguments(key: key, group: group),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithHomeView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.homeView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithStartupView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.startupView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithPlaylistView({
    _i6.Key? key,
    required _i7.Playlist playlist,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.playlistView,
        arguments: PlaylistViewArguments(key: key, playlist: playlist),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithFolderPlaylistsView({
    _i6.Key? key,
    required _i8.ParentFolderGroup group,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.folderPlaylistsView,
        arguments: FolderPlaylistsViewArguments(key: key, group: group),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }
}
