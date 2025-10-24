import 'package:divine_stream/utils/sort_audio_files.dart';

import 'audio_file.dart';

class Playlist {
  final String id; // Unique ID for the playlist
  final String name; // Playlist name (subfolder name from Google Drive)
  final List<AudioFile> audioFiles; // List of audio files in this playlist

  /// Stores the persisted track ID we should highlight when this playlist opens.
  final String? lastPlayedTrackId;

  ///  When populated, this manifest belongs to a grouped parent folder entry.
  final String? parentFolderId;

  ///  Friendly name shown alongside the parent tile on the home screen.
  final String? parentFolderName;

  Playlist({
    required this.id,
    required this.name,
    required this.audioFiles,
    this.lastPlayedTrackId,
    this.parentFolderId,
    this.parentFolderName,
  });

  Playlist copyWith({
    String? id,
    String? name,
    List<AudioFile>? audioFiles,
    String? lastPlayedTrackId,
    String? parentFolderId,
    String? parentFolderName,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      audioFiles: audioFiles ?? this.audioFiles,
      lastPlayedTrackId: lastPlayedTrackId ?? this.lastPlayedTrackId,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      parentFolderName: parentFolderName ?? this.parentFolderName,
    );
  }

  /// Convert from JSON (when fetching from local storage or API)
  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawList = json['audioFiles'] as List<dynamic>?;

    final audioFiles = rawList?.map((entry) {
          // Ensure each entry is a Map<String, dynamic>
          final Map<String, dynamic> fileMap = entry is Map<String, dynamic>
              ? entry
              : Map<String, dynamic>.from(entry as Map);
          return AudioFile.fromJson(fileMap);
        }).toList() ??
        [];

    final orderedAudioFiles = List<AudioFile>.from(audioFiles)
      ..sort(audioFileComparator); //  Keep cached playlists sorted like fresh manifests.

    return Playlist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      audioFiles: orderedAudioFiles,
      lastPlayedTrackId: json['lastPlayedTrackId'] as String?,
      parentFolderId: json['parentFolderId'] as String?,
      parentFolderName: json['parentFolderName'] as String?,
    );
  }

  /// Convert to JSON (when saving to local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'audioFiles': audioFiles.map((file) => file.toJson()).toList(),
      'lastPlayedTrackId': lastPlayedTrackId,
      'parentFolderId': parentFolderId,
      'parentFolderName': parentFolderName,
    };
  }

  /// Find an audio file by ID
  AudioFile? findAudioFile(String fileId) {
    return audioFiles.firstWhere((file) => file.id == fileId,
        orElse: () => AudioFile.empty());
  }

  /// Returns the index of the stored last played track, if we still have it.
  int? lastPlayedIndex() {
    if (lastPlayedTrackId == null) return null;
    final index = audioFiles.indexWhere((file) => file.id == lastPlayedTrackId);
    return index >= 0 ? index : null;
  }

  /// Create an empty playlist
  static Playlist empty() {
    return Playlist(id: '', name: '', audioFiles: []);
  }
}
