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

  /// Import a playlist by fetching audio files from the given folder ID.
  Future<List<Playlist>> scanNestedFolders(String parentFolderId) async {
    final List<Playlist> playlists = [];

    // Step 1: Fetch subfolders
    final subfolders = await fetchSubFolders(parentFolderId);

    if (subfolders.isNotEmpty) {
      for (final folder in subfolders) {
        final audioFilesData = await fetchAudioFiles(folder['id']);

        if (audioFilesData.isNotEmpty) {
          final audioFiles = audioFilesData
              .map((data) => AudioFile.fromJson(data))
              .toList()
            ..sort(
                audioFileComparator); // numeric-aware ordering for track names

          playlists.add(Playlist(
            id: folder['id'],
            name: folder['name'] ?? 'Unnamed Playlist',
            audioFiles: audioFiles,
          ));
        } else {
          // Dive deeper recursively
          final deeperPlaylists = await scanNestedFolders(folder['id']);
          playlists.addAll(deeperPlaylists);
        }
      }
    } else {
      // No subfolders — check current folder for audio files
      final audioFilesData = await fetchAudioFiles(parentFolderId);

      if (audioFilesData.isNotEmpty) {
        final audioFiles = audioFilesData
            .map((data) => AudioFile.fromJson(data))
            .toList()
          ..sort(audioFileComparator); // numeric-aware ordering for track names

        final folderInfo = await fetchFolderInfo(parentFolderId);
        final name = folderInfo['name'] ?? "Unnamed Playlist";

        playlists.add(Playlist(
          id: parentFolderId,
          name: name,
          audioFiles: audioFiles,
        ));
      }
    }

    return playlists;
  }
}
