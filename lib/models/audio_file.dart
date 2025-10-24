class AudioFile {
  final String id;
  final String title;
  final String url;
  final String name;

  AudioFile({
    required this.id,
    required this.title,
    required this.url,
    required this.name,
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    // Strip legacy Drive API keys from cached URLs
    // so Firebase links remain valid
    String sanitizedUrl = json['url'] ?? '';
    try {
      final uri = Uri.parse(sanitizedUrl);
      if (uri.queryParameters.containsKey('key')) {
        final filteredParams = Map<String, String>.from(uri.queryParameters)
          ..remove('key');
        sanitizedUrl = uri.replace(queryParameters: filteredParams).toString();
      }
    } catch (_) {
      // Leave the original value if parsing fails;
      // playback will surface the error
    }

    return AudioFile(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      url: sanitizedUrl,
      name: _stripExtension(json['name']),
    );
  }


  ///  Remove trailing file extensions so the playlist UI
  ///  shows human-friendly titles
  static String _stripExtension(String? name) {
    if (name == null || name.isEmpty) return '';
    final index = name.lastIndexOf('.');
    if (index <= 0) return name;
    return name.substring(0, index);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'name': name,
    };
  }

  /// Create an empty AudioFile
  static AudioFile empty() {
    return AudioFile(id: '', title: '', url: '', name: '');
  }
}
