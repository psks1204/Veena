/// Media Item Model
///
/// Represents a media item from the API (video or audio content).
/// Includes nested artist and album information.
library;

/// Artist information embedded in media response
class ArtistInfo {
  final int id;
  final String name;
  final String? genre;
  final String? bio;
  final String? imageUrl;
  final bool verified;
  final int followerCount;

  const ArtistInfo({
    required this.id,
    required this.name,
    this.genre,
    this.bio,
    this.imageUrl,
    this.verified = false,
    this.followerCount = 0,
  });

  factory ArtistInfo.fromJson(Map<String, dynamic> json) {
    return ArtistInfo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'Unknown Artist',
      genre: json['genre'] as String?,
      bio: json['bio'] as String?,
      imageUrl: json['imageUrl'] as String?,
      verified: json['verified'] as bool? ?? false,
      followerCount: json['followerCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'genre': genre,
    'bio': bio,
    'imageUrl': imageUrl,
    'verified': verified,
    'followerCount': followerCount,
  };
}

/// Album information embedded in media response
class AlbumInfo {
  final int id;
  final String name;
  final String? description;
  final String? coverImageUrl;

  const AlbumInfo({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
  });

  factory AlbumInfo.fromJson(Map<String, dynamic> json) {
    return AlbumInfo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'Unknown Album',
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'coverImageUrl': coverImageUrl,
  };
}

/// Linked media (audio-video pair) information
class LinkedMediaInfo {
  final String id;
  final String title;
  final MediaType mediaType;
  final String? thumbnailUrl;
  final String? hlsUrl;
  final ArtistInfo? artist;
  final List<ArtistInfo> subArtists;
  final String? composerName;
  final String? lyricistName;
  final String? producerName;
  final String? directorName;
  final CreditInfo? composer;
  final CreditInfo? lyricist;
  final CreditInfo? producer;
  final CreditInfo? director;
  final AlbumInfo? album;
  final String? releaseDate;

  const LinkedMediaInfo({
    required this.id,
    required this.title,
    required this.mediaType,
    this.thumbnailUrl,
    this.hlsUrl,
    this.artist,
    this.subArtists = const [],
    this.composerName,
    this.lyricistName,
    this.producerName,
    this.directorName,
    this.composer,
    this.lyricist,
    this.producer,
    this.director,
    this.album,
    this.releaseDate,
  });

  factory LinkedMediaInfo.fromJson(Map<String, dynamic> json) {
    return LinkedMediaInfo(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      mediaType: MediaType.fromString(json['mediaType'] as String? ?? 'AUDIO'),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      artist: json['artist'] != null
          ? ArtistInfo.fromJson(json['artist'] as Map<String, dynamic>)
          : null,
      subArtists: (json['subArtists'] as List<dynamic>?)
              ?.map((e) => ArtistInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      composerName: json['composerName'] as String?,
      lyricistName: json['lyricistName'] as String?,
      producerName: json['producerName'] as String?,
      directorName: json['directorName'] as String?,
      composer: json['composer'] != null
          ? CreditInfo.fromJson(json['composer'] as Map<String, dynamic>)
          : null,
      lyricist: json['lyricist'] != null
          ? CreditInfo.fromJson(json['lyricist'] as Map<String, dynamic>)
          : null,
      producer: json['producer'] != null
          ? CreditInfo.fromJson(json['producer'] as Map<String, dynamic>)
          : null,
      director: json['director'] != null
          ? CreditInfo.fromJson(json['director'] as Map<String, dynamic>)
          : null,
      album: json['album'] != null
          ? AlbumInfo.fromJson(json['album'] as Map<String, dynamic>)
          : null,
      releaseDate: json['releaseDate'] as String?,
    );
  }

  factory LinkedMediaInfo.fromMediaItem(MediaItem item) {
    return LinkedMediaInfo(
      id: item.id,
      title: item.title,
      mediaType: item.mediaType,
      thumbnailUrl: item.thumbnailUrl,
      hlsUrl: item.hlsUrl,
      artist: item.artist,
      subArtists: item.subArtists,
      composerName: item.composerName,
      lyricistName: item.lyricistName,
      producerName: item.producerName,
      directorName: item.directorName,
      composer: item.composer,
      lyricist: item.lyricist,
      producer: item.producer,
      director: item.director,
      album: item.album,
      releaseDate: item.releaseDate,
    );
  }
}

/// Like response from the API
class LikeResponse {
  final bool liked;
  final int likeCount;

  const LikeResponse({required this.liked, required this.likeCount});

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      liked: json['liked'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
    );
  }
}

/// Credit information (Composer/Lyricist)
class CreditInfo {
  final int id;
  final String name;
  final String? bio;
  final String? imageUrl;
  final String? creditType;

  const CreditInfo({
    required this.id,
    required this.name,
    this.bio,
    this.imageUrl,
    this.creditType,
  });

  factory CreditInfo.fromJson(Map<String, dynamic> json) {
    return CreditInfo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      bio: json['bio'] as String?,
      imageUrl: json['imageUrl'] as String?,
      creditType: json['creditType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bio': bio,
    'imageUrl': imageUrl,
    'creditType': creditType,
  };
}

/// Media Item - main content model
class MediaItem {
  final String id;
  final String title;
  final String? description;
  final MediaType mediaType;
  final MediaStatus status;
  final MediaVisibility visibility;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final String? lyricsUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? linkedMediaId;
  final bool liked;
  final int likeCount;
  final int playedCount;
  final ArtistInfo? artist;
  final List<ArtistInfo> subArtists;
  final String? composerName;
  final String? lyricistName;
  final String? producerName;
  final String? directorName;
  final CreditInfo? composer;
  final CreditInfo? lyricist;
  final CreditInfo? producer;
  final CreditInfo? director;
  final AlbumInfo? album;
  final String? releaseDate;
  final LinkedMediaInfo? linkedMedia;
  final String? featuredImageUrl;
  final bool isChannelMedia;
  final bool karaoke;

  const MediaItem({
    required this.id,
    required this.title,
    this.description,
    required this.mediaType,
    required this.status,
    this.visibility = MediaVisibility.public,
    this.hlsUrl,
    this.thumbnailUrl,
    this.lyricsUrl,
    required this.createdAt,
    required this.updatedAt,
    this.linkedMediaId,
    this.liked = false,
    this.likeCount = 0,
    this.playedCount = 0,
    this.artist,
    this.subArtists = const [],
    this.composerName,
    this.lyricistName,
    this.producerName,
    this.directorName,
    this.composer,
    this.lyricist,
    this.producer,
    this.director,
    this.album,
    this.releaseDate,
    this.linkedMedia,
    this.featuredImageUrl,
    this.isChannelMedia = false,
    this.karaoke = false,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      mediaType: MediaType.fromString(json['mediaType'] as String? ?? 'AUDIO'),
      status: MediaStatus.fromString(json['status'] as String? ?? 'PUBLISHED'),
      visibility: MediaVisibility.fromString(
        json['visibility'] as String? ?? 'PUBLIC',
      ),
      hlsUrl: json['hlsUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      featuredImageUrl: json['featuredImageUrl'] as String?,
      lyricsUrl: json['lyricsUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      linkedMediaId: json['linkedMediaId'] as String?,
      liked: json['liked'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      playedCount: json['playedCount'] as int? ?? 0,
      artist: json['artist'] != null
          ? ArtistInfo.fromJson(json['artist'] as Map<String, dynamic>)
          : null,
      subArtists:
          (json['subArtists'] as List<dynamic>?)
              ?.map((e) => ArtistInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      composerName: json['composerName'] as String?,
      lyricistName: json['lyricistName'] as String?,
      producerName: json['producerName'] as String?,
      directorName: json['directorName'] as String?,
      composer: json['composer'] != null
          ? CreditInfo.fromJson(json['composer'] as Map<String, dynamic>)
          : null,
      lyricist: json['lyricist'] != null
          ? CreditInfo.fromJson(json['lyricist'] as Map<String, dynamic>)
          : null,
      producer: json['producer'] != null
          ? CreditInfo.fromJson(json['producer'] as Map<String, dynamic>)
          : null,
      director: json['director'] != null
          ? CreditInfo.fromJson(json['director'] as Map<String, dynamic>)
          : null,
      album: json['album'] != null
          ? AlbumInfo.fromJson(json['album'] as Map<String, dynamic>)
          : null,
      releaseDate: json['releaseDate'] as String?,
      linkedMedia: json['linkedMedia'] != null
          ? LinkedMediaInfo.fromJson(
              json['linkedMedia'] as Map<String, dynamic>,
            )
          : null,
      isChannelMedia: json['isChannelMedia'] as bool? ?? false,
      karaoke: json['karaoke'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'mediaType': mediaType.value,
    'status': status.value,
    'visibility': visibility.value,
    'hlsUrl': hlsUrl,
    'thumbnailUrl': thumbnailUrl,
    'featuredImageUrl': featuredImageUrl,
    'lyricsUrl': lyricsUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'linkedMediaId': linkedMediaId,
    'liked': liked,
    'likeCount': likeCount,
    'playedCount': playedCount,
    'artist': artist?.toJson(),
    'subArtists': subArtists.map((e) => e.toJson()).toList(),
    'composerName': composerName,
    'lyricistName': lyricistName,
    'producerName': producerName,
    'directorName': directorName,
    'composer': composer?.toJson(),
    'lyricist': lyricist?.toJson(),
    'producer': producer?.toJson(),
    'director': director?.toJson(),
    'album': album?.toJson(),
    'releaseDate': releaseDate,
    'isChannelMedia': isChannelMedia,
    'karaoke': karaoke,
  };

  /// Helper to get artist name
  String get artistName => artist?.name ?? description ?? '';

  /// Helper to get full artist string (Main + Sub)
  String get fullArtistString {
    if (subArtists.isEmpty) return artistName;
    return '$artistName feat. ${subArtists.map((e) => e.name).join(", ")}';
  }

  /// Helper to get all contributors/credits as a formatted string
  String get allCreditsString {
    List<String> parts = [];

    // Artists
    parts.add(fullArtistString);

    // Lyricist
    final lName = lyricist?.name ?? lyricistName;
    if (lName != null && lName.isNotEmpty) {
      parts.add('Lyricist: $lName');
    }

    // Composer
    final cName = composer?.name ?? composerName;
    if (cName != null && cName.isNotEmpty) {
      parts.add('Composer: $cName');
    }

    // Producer
    final pName = producer?.name ?? producerName;
    if (pName != null && pName.isNotEmpty) {
      parts.add('Producer: $pName');
    }

    // Director
    final dName = director?.name ?? directorName;
    if (dName != null && dName.isNotEmpty) {
      parts.add('Director: $dName');
    }

    return parts.join(' • ');
  }

  /// Helper to get album name
  String? get albumName => album?.name;

  /// Helper to get album cover (falls back to thumbnail)
  String? get albumCoverUrl => album?.coverImageUrl ?? thumbnailUrl;

  /// Effective credit names (prefers CreditInfo.name, falls back to String credit name)
  String? get effectiveComposerName => composer?.name ?? composerName;
  String? get effectiveLyricistName => lyricist?.name ?? lyricistName;
  String? get effectiveProducerName => producer?.name ?? producerName;
  String? get effectiveDirectorName => director?.name ?? directorName;
  bool get hasCredits =>
      effectiveComposerName != null ||
      effectiveLyricistName != null ||
      effectiveProducerName != null ||
      effectiveDirectorName != null ||
      releaseDate != null;

  bool get isVideo => mediaType == MediaType.video;
  bool get isAudio => mediaType == MediaType.audio;
  bool get isPublished => status == MediaStatus.published;
  bool get hasLinkedMedia => linkedMediaId != null || linkedMedia != null;

  /// Convenience getter for karaoke flag
  bool get isKaraoke => karaoke;

  /// Helper to get artist ID as String
  String? get artistId => artist?.id.toString();

  /// Create a MediaItem from LinkedMediaInfo, preserving credits & artist info from currentMedia if needed
  factory MediaItem.fromLinkedMedia(
    LinkedMediaInfo linked, {
    MediaItem? currentMedia,
  }) {
    // Preserve artist info; ensure imageUrl, followerCount, and ID from currentMedia if linked.artist lacks them
    ArtistInfo? mergedArtist = linked.artist ?? currentMedia?.artist;
    if (mergedArtist != null && currentMedia?.artist != null) {
      final ca = currentMedia!.artist!;
      mergedArtist = ArtistInfo(
        id: mergedArtist.id != 0 ? mergedArtist.id : ca.id,
        name: (mergedArtist.name.isNotEmpty && mergedArtist.name != 'Unknown Artist')
            ? mergedArtist.name
            : ca.name,
        genre: mergedArtist.genre ?? ca.genre,
        bio: mergedArtist.bio ?? ca.bio,
        imageUrl: (mergedArtist.imageUrl != null && mergedArtist.imageUrl!.isNotEmpty)
            ? mergedArtist.imageUrl
            : ca.imageUrl,
        verified: mergedArtist.verified || ca.verified,
        followerCount: mergedArtist.followerCount > 0
            ? mergedArtist.followerCount
            : ca.followerCount,
      );
    }

    final subArtists = linked.subArtists.isNotEmpty
        ? linked.subArtists
        : (currentMedia?.subArtists ?? const []);

    final composer = linked.composer ?? currentMedia?.composer;
    final lyricist = linked.lyricist ?? currentMedia?.lyricist;
    final producer = linked.producer ?? currentMedia?.producer;
    final director = linked.director ?? currentMedia?.director;

    final composerName =
        linked.composerName ?? currentMedia?.composerName ?? composer?.name;
    final lyricistName =
        linked.lyricistName ?? currentMedia?.lyricistName ?? lyricist?.name;
    final producerName =
        linked.producerName ?? currentMedia?.producerName ?? producer?.name;
    final directorName =
        linked.directorName ?? currentMedia?.directorName ?? director?.name;

    LinkedMediaInfo? backLink;
    if (currentMedia != null) {
      backLink = LinkedMediaInfo.fromMediaItem(currentMedia);
    }

    return MediaItem(
      id: linked.id,
      title: linked.title,
      mediaType: linked.mediaType,
      thumbnailUrl: linked.thumbnailUrl ?? currentMedia?.thumbnailUrl,
      hlsUrl: linked.hlsUrl ?? currentMedia?.hlsUrl,
      status: MediaStatus.published,
      createdAt: currentMedia?.createdAt ?? DateTime.now(),
      updatedAt: currentMedia?.updatedAt ?? DateTime.now(),
      artist: mergedArtist,
      subArtists: subArtists,
      composerName: composerName,
      lyricistName: lyricistName,
      producerName: producerName,
      directorName: directorName,
      composer: composer,
      lyricist: lyricist,
      producer: producer,
      director: director,
      album: linked.album ?? currentMedia?.album,
      releaseDate: linked.releaseDate ?? currentMedia?.releaseDate,
      lyricsUrl: currentMedia?.lyricsUrl,
      featuredImageUrl: currentMedia?.featuredImageUrl,
      liked: currentMedia?.liked ?? false,
      likeCount: currentMedia?.likeCount ?? 0,
      playedCount: currentMedia?.playedCount ?? 0,
      isChannelMedia: currentMedia?.isChannelMedia ?? false,
      karaoke: currentMedia?.karaoke ?? false,
      linkedMedia: backLink,
    );
  }

  /// Enrich this MediaItem with metadata from a detailed API response [fullItem]
  MediaItem enrichWith(MediaItem fullItem) {
    ArtistInfo? mergedArtist = fullItem.artist ?? artist;
    if (mergedArtist != null && artist != null) {
      mergedArtist = ArtistInfo(
        id: mergedArtist.id != 0 ? mergedArtist.id : artist!.id,
        name: (mergedArtist.name.isNotEmpty && mergedArtist.name != 'Unknown Artist')
            ? mergedArtist.name
            : artist!.name,
        genre: mergedArtist.genre ?? artist!.genre,
        bio: mergedArtist.bio ?? artist!.bio,
        imageUrl: (mergedArtist.imageUrl != null && mergedArtist.imageUrl!.isNotEmpty)
            ? mergedArtist.imageUrl
            : artist!.imageUrl,
        verified: mergedArtist.verified || artist!.verified,
        followerCount: mergedArtist.followerCount > 0
            ? mergedArtist.followerCount
            : artist!.followerCount,
      );
    }

    return MediaItem(
      id: id,
      title: fullItem.title.isNotEmpty ? fullItem.title : title,
      description: fullItem.description ?? description,
      mediaType: mediaType,
      status: status,
      visibility: visibility,
      hlsUrl: fullItem.hlsUrl ?? hlsUrl,
      thumbnailUrl: fullItem.thumbnailUrl ?? thumbnailUrl,
      lyricsUrl: fullItem.lyricsUrl ?? lyricsUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      linkedMediaId: fullItem.linkedMediaId ?? linkedMediaId,
      liked: fullItem.liked || liked,
      likeCount: fullItem.likeCount > 0 ? fullItem.likeCount : likeCount,
      playedCount: fullItem.playedCount > 0 ? fullItem.playedCount : playedCount,
      artist: mergedArtist,
      subArtists: fullItem.subArtists.isNotEmpty ? fullItem.subArtists : subArtists,
      composerName: fullItem.composerName ?? composerName,
      lyricistName: fullItem.lyricistName ?? lyricistName,
      producerName: fullItem.producerName ?? producerName,
      directorName: fullItem.directorName ?? directorName,
      composer: fullItem.composer ?? composer,
      lyricist: fullItem.lyricist ?? lyricist,
      producer: fullItem.producer ?? producer,
      director: fullItem.director ?? director,
      album: fullItem.album ?? album,
      releaseDate: fullItem.releaseDate ?? releaseDate,
      linkedMedia: fullItem.linkedMedia ?? linkedMedia,
      featuredImageUrl: fullItem.featuredImageUrl ?? featuredImageUrl,
      isChannelMedia: isChannelMedia,
      karaoke: karaoke,
    );
  }
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
      orElse: () => MediaType.audio,
    );
  }
}

/// Media status enum - matches API values
enum MediaStatus {
  draft('DRAFT'),
  processing('PROCESSING'),
  published('PUBLISHED'),
  failed('FAILED');

  final String value;
  const MediaStatus(this.value);

  static MediaStatus fromString(String value) {
    // Handle legacy values
    final normalized = value.toUpperCase();
    if (normalized == 'READY') return MediaStatus.published;
    if (normalized == 'PENDING') return MediaStatus.draft;

    return MediaStatus.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => MediaStatus.draft,
    );
  }
}

/// Media visibility enum
enum MediaVisibility {
  public('PUBLIC'),
  private_('PRIVATE'),
  unlisted('UNLISTED');

  final String value;
  const MediaVisibility(this.value);

  static MediaVisibility fromString(String value) {
    return MediaVisibility.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => MediaVisibility.public,
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
      pageNumber:
          pageable?['pageNumber'] as int? ?? json['number'] as int? ?? 0,
      pageSize: pageable?['pageSize'] as int? ?? json['size'] as int? ?? 20,
      isFirst: json['first'] as bool? ?? true,
      isLast: json['last'] as bool? ?? true,
    );
  }

  /// Check if there are more pages
  bool get hasMore => !isLast;
}
