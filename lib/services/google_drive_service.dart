import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/audio_file.dart';
import '../models/playlist.dart';

class GoogleDriveService {

  final api_key = "AIzaSyCEvTZQRCj8Gc2-y6NIAJVh2Y8mI4FVipY";

  /// Fetch direct subfolders under a given parent folder
  Future<List<Map<String, dynamic>>> fetchSubFolders(
      String parentFolderId) async {
    final url =
        "https://www.googleapis.com/drive/v3/files?q='$parentFolderId'+in+parents+and+mimeType='application/vnd.google-apps.folder'&fields=files(id,name)&key=$api_key";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List files = data['files'];
      return files.map<Map<String, dynamic>>((folder) {
        return {'id': folder['id'], 'name': folder['name']};
      }).toList();
    } else {
      throw Exception("Failed to fetch subfolders: ${response.body}");
    }
  }

  /// Fetch audio files in a specific folder (non-recursive)
  Future<List<Map<String, dynamic>>> fetchAudioFiles(String folderId) async {
    final url = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files',
      {
        'q': "'$folderId' in parents and mimeType contains 'audio/'",
        'fields': 'files(id,name,webContentLink)',
        'key': api_key,
      },
    ).toString();


    //"https://www.googleapis.com/drive/v3/files?q='$folderId'+in+parents+and+mimeType+contains+'audio/'&fields=files(id,name,webContentLink)&key=$api_key";
    print("🔄 fetchAudioFiles URL: $url");
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List files = data['files'];
      print("🔄 fetchAudioFiles returned ${files.length} items");
      return files.map<Map<String, dynamic>>((file) {
        return {
          'id': file['id'],
          'name': file['name'],
          'url':
          'https://www.googleapis.com/drive/v3/files/${file['id']}?alt=media&key=$api_key',
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
            ..sort((a, b) => a.name.compareTo(b.name)); // ✅ sort here

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
          ..sort((a, b) => a.name.compareTo(b.name)); // ✅ sort here too

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
