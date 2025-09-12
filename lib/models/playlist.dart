import 'audio_file.dart';

class Playlist {
  final String id; // Unique ID for the playlist
  final String name; // Playlist name (subfolder name from Google Drive)
  final List<AudioFile> audioFiles; // List of audio files in this playlist

  Playlist({required this.id, required this.name, required this.audioFiles});

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

    return Playlist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      audioFiles: audioFiles,
    );
  }

  /// Convert to JSON (when saving to local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'audioFiles': audioFiles.map((file) => file.toJson()).toList(),
    };
  }

  /// Find an audio file by ID
  AudioFile? findAudioFile(String fileId) {
    return audioFiles.firstWhere((file) => file.id == fileId,
        orElse: () => AudioFile.empty());
  }

  /// Create an empty playlist
  static Playlist empty() {
    return Playlist(id: '', name: '', audioFiles: []);
  }
}
