import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/audio_file.dart';
import '../models/playlist.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/sort_audio_files.dart';

class GoogleDriveService {
  final api_key = dotenv.env['GOOGLE_DRIVE_API_KEY'] ?? '';

  /// Fetch direct subfolders under a given parent folder
  Future<List<Map<String, dynamic>>> fetchSubFolders(
      String parentFolderId) async {
    final url =
        "https://www.googleapis.com/drive/v3/files?q='$parentFolderId'+in+parents+and+mimeType='application/vnd.google-apps.folder'&fields=files(id,name)&key=$api_key";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> files = (data['files'] as List?) ?? const [];
      return files.map<Map<String, dynamic>>((folder) {
        return {'id': folder['id'], 'name': folder['name']};
      }).toList();
    } else {
      throw Exception("Failed to fetch subfolders: ${response.body}");
    }
  }

  /// Fetch audio files in a specific folder (non-recursive)
  Future<List<Map<String, dynamic>>> fetchAudioFiles(String folderId) async {
    // Allow both native audio mime-types and generic binary uploads so we catch
    // files that Drive stores as `application/octet-stream` even when they are
    // audio tracks.
    final query =
        "'$folderId' in parents and (mimeType contains 'audio/' or mimeType = 'application/octet-stream')";

    final url = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files',
      {
        'q': query,
        'fields': 'files(id,name,webContentLink)',
        'key': api_key,
      },
    ).toString();

    //"https://www.googleapis.com/drive/v3/files?q='$folderId'+in+parents+and+mimeType+contains+'audio/'&fields=files(id,name,webContentLink)&key=$api_key";
    print("🔄 fetchAudioFiles URL: $url");
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> files = (data['files'] as List?) ?? const [];

      // Filter by common audio extensions to avoid pulling non-audio binaries
      // that matched the broader Drive query above.
      const allowedExtensions = [
        '.aac',
        '.m4a',
        '.mp3',
        '.oga',
        '.ogg',
        '.opus',
        '.wav',
      ];

      bool hasAllowedExtension(String? name) {
        if (name == null) return false;
        final lowerName = name.toLowerCase();
        return allowedExtensions.any(lowerName.endsWith);
      }

      for (final file in files) {
        final name = file['name'];
        print('🔍 Drive returned file: $name');
      }

      final filteredFiles =
          files.where((file) => hasAllowedExtension(file['name'])).toList();

      print(
          "fetchAudioFiles returned ${filteredFiles.length} items after filtering");
      return filteredFiles.map<Map<String, dynamic>>((file) {
        return {
          'id': file['id'],
          'name': file['name'],
          // Public files can be streamed without an API key; omitting the key
          // keeps cached URLs from breaking if the key is rotated later.
          'url':
              'https://www.googleapis.com/drive/v3/files/${file['id']}?alt=media',
        };
      }).toList();
    } else {
      throw Exception("Failed to fetch audio files: ${response.body}");
    }
  }

  /// Fetch folder metadata (e.g., name)
  Future<Map<String, dynamic>> fetchFolderInfo(String folderId) async {
    final url =
        "https://www.googleapis.com/drive/v3/files/$folderId?fields=id,name&key=$api_key";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'name': 'Unnamed Playlist'};
    }
  }

  /// Import playlists under the given folder, tagging child playlists with the root folder.
  Future<List<Playlist>> scanNestedFolders(
    String folderId, {
    String? rootFolderId,
    String? rootFolderName,
    bool isRoot = false,
  }) async {
    final List<Playlist> playlists = [];

    // Establish parent metadata once so every descendant can reference the top folder.
    final bool isInitialCall = isRoot || rootFolderId == null;
    final String effectiveRootId = rootFolderId ?? folderId;
    var effectiveRootName = rootFolderName;

    if (effectiveRootName == null) {
      final rootInfo = await fetchFolderInfo(effectiveRootId);
      effectiveRootName = rootInfo['name'] ?? 'Unnamed Playlist';
    }

    // Sort subfolders with the shared comparator so nested playlists respect numeric prefixes.
    final subfolders = await fetchSubFolders(folderId)
      ..sort((a, b) =>
          numericAwareNameCompare(a['name'] as String?, b['name'] as String?));

    if (subfolders.isNotEmpty) {
      for (final folder in subfolders) {
        final audioFilesData = await fetchAudioFiles(folder['id']);

        if (audioFilesData.isNotEmpty) {
          final audioFiles = audioFilesData
              .map((data) => AudioFile.fromJson(data))
              .toList()
            ..sort(
                audioFileComparator); // numeric-aware ordering for track names

          // Tag child playlists with the root metadata so the UI can treat them as part of a folder.
          playlists.add(Playlist(
            id: folder['id'],
            name: folder['name'] ?? 'Unnamed Playlist',
            audioFiles: audioFiles,
            parentFolderId: effectiveRootId,
            parentFolderName: effectiveRootName,
          ));
        } else {
          // Dive deeper recursively so grand-child folders still belong to the root group.
          final deeperPlaylists = await scanNestedFolders(
            folder['id'],
            rootFolderId: effectiveRootId,
            rootFolderName: effectiveRootName,
          );
          playlists.addAll(deeperPlaylists);
        }
      }

      if (isInitialCall) {
        final rootAudioFiles = await fetchAudioFiles(folderId);
        if (rootAudioFiles.isNotEmpty) {
          final audioFiles = rootAudioFiles
              .map((data) => AudioFile.fromJson(data))
              .toList()
            ..sort(audioFileComparator);

          // Also surface audio files that live directly under the root folder.
          playlists.add(Playlist(
            id: folderId,
            name: effectiveRootName!,
            audioFiles: audioFiles,
            parentFolderId: effectiveRootId,
            parentFolderName: effectiveRootName,
          ));
        }
      }
    } else {
      final audioFilesData = await fetchAudioFiles(folderId);

      if (audioFilesData.isNotEmpty) {
        final audioFiles = audioFilesData
            .map((data) => AudioFile.fromJson(data))
            .toList()
          ..sort(audioFileComparator);

        // Pull the folder name when we are not dealing with the root.
        final folderInfo = isInitialCall
            ? {'name': effectiveRootName}
            : await fetchFolderInfo(folderId);
        final playlistName = folderInfo['name'] ?? 'Unnamed Playlist';

        // Root-level folders (no subfolders) stay standalone unless metadata marks them as children.
        playlists.add(Playlist(
          id: folderId,
          name: playlistName,
          audioFiles: audioFiles,
          parentFolderId: isInitialCall ? null : effectiveRootId,
          parentFolderName: isInitialCall ? null : effectiveRootName,
        ));
      }
    }

    // Return playlists sorted so cache and UI ordering match.
    playlists.sort((a, b) => numericAwareNameCompare(a.name, b.name));
    return playlists;
  }
}
