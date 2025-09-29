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
    // If older cache entries still include an API key query param, strip it so
    // the URL stays valid even after the key changes.
    String sanitizedUrl = json['url'] ?? '';
    try {
      final uri = Uri.parse(sanitizedUrl);
      if (uri.queryParameters.containsKey('key')) {
        final filteredParams = Map<String, String>.from(uri.queryParameters)
          ..remove('key');
        sanitizedUrl = uri.replace(queryParameters: filteredParams).toString();
      }
    } catch (_) {
      // Leave the original value if parsing fails; playback will surface the error.
    }

    return AudioFile(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      url: sanitizedUrl,
      name: json['name'],
    );
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
