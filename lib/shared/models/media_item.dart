class MediaItem {
  final String id;
  final String title;
  final String description;
  final String mediaType;
  final String artistName;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final String? lyricsUrl;
  final int playCount;
  bool isLiked;
  int likeCount;

  MediaItem({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaType,
    required this.artistName,
    this.hlsUrl,
    this.thumbnailUrl,
    this.lyricsUrl,
    this.playCount = 0,
    this.isLiked = false,
    this.likeCount = 0,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      mediaType: json['mediaType'],
      artistName: json['artist']?['name'] ?? 'Unknown Artist',
      hlsUrl: json['hlsUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      lyricsUrl: json['lyricsUrl'],
      playCount: json['playCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      likeCount: json['likeCount'] ?? 0,
    );
  }

  MediaItem copyWith({
    String? id,
    String? title,
    String? description,
    String? mediaType,
    String? artistName,
    String? hlsUrl,
    String? thumbnailUrl,
    String? lyricsUrl,
    int? playCount,
    bool? isLiked,
    int? likeCount,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaType: mediaType ?? this.mediaType,
      artistName: artistName ?? this.artistName,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      lyricsUrl: lyricsUrl ?? this.lyricsUrl,
      playCount: playCount ?? this.playCount,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}
