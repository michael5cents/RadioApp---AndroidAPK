class RadioStation {
  final String name;
  final String url;
  final String genre;
  String currentTitle = '';
  String currentArtist = '';
  bool supportsMetadata = false;

  RadioStation({
    required this.name,
    required this.url,
    required this.genre,
    this.supportsMetadata = false,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'genre': genre,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadioStation &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => '$name ($genre)';
}