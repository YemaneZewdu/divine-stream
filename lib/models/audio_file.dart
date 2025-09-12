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
    return AudioFile(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
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
