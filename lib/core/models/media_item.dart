/// Media Item Model
/// 
/// Represents a media item from the API (video or audio content).
class MediaItem {
  final String id;
  final String title;
  final String? description;
  final MediaType mediaType;
  final MediaStatus status;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final String? lyricsUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MediaItem({
    required this.id,
    required this.title,
    this.description,
    required this.mediaType,
    required this.status,
    this.hlsUrl,
    this.thumbnailUrl,
    this.lyricsUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      mediaType: MediaType.fromString(json['mediaType'] as String),
      status: MediaStatus.fromString(json['status'] as String),
      hlsUrl: json['hlsUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      lyricsUrl: json['lyricsUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'mediaType': mediaType.value,
    'status': status.value,
    'hlsUrl': hlsUrl,
    'thumbnailUrl': thumbnailUrl,
    'lyricsUrl': lyricsUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  bool get isVideo => mediaType == MediaType.video;
  bool get isAudio => mediaType == MediaType.audio;
  bool get isReady => status == MediaStatus.ready;
}

/// Media type enum
enum MediaType {
  video('VIDEO'),
  audio('AUDIO');

  final String value;
  const MediaType(this.value);

  static MediaType fromString(String value) {
    return MediaType.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => MediaType.video,
    );
  }
}

/// Media status enum
enum MediaStatus {
  pending('PENDING'),
  processing('PROCESSING'),
  ready('READY'),
  failed('FAILED');

  final String value;
  const MediaStatus(this.value);

  static MediaStatus fromString(String value) {
    return MediaStatus.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => MediaStatus.pending,
    );
  }
}

/// Paged response from API
class PagedResponse<T> {
  final List<T> content;
  final int totalPages;
  final int totalElements;
  final int pageNumber;
  final int pageSize;
  final bool isFirst;
  final bool isLast;

  const PagedResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.pageNumber,
    required this.pageSize,
    required this.isFirst,
    required this.isLast,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final contentList = (json['content'] as List)
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();

    final pageable = json['pageable'] as Map<String, dynamic>?;

    return PagedResponse<T>(
      content: contentList,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? contentList.length,
      pageNumber: pageable?['pageNumber'] as int? ?? 0,
      pageSize: pageable?['pageSize'] as int? ?? 10,
      isFirst: json['first'] as bool? ?? true,
      isLast: json['last'] as bool? ?? true,
    );
  }
}
