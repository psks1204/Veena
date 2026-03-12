class Artist {
  final String id;
  final String name;
  final String? imageUrl;
  final String? genre;
  final String? country;
  final String? bio;
  final int followerCount;
  final int totalPlays;
  final bool following;
  final bool verified;
  
  Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.genre,
    this.country,
    this.bio,
    this.followerCount = 0,
    this.totalPlays = 0,
    this.following = false,
    this.verified = false,
  });
  
  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: (json['id'] ?? json['artistId'] ?? '').toString(),
      name: json['name'] ?? json['artistName'] ?? 'Unknown Artist',
      imageUrl: json['imageUrl'] ?? json['artistImageUrl'] ?? json['thumbnailUrl'],
      genre: json['genre'] as String?,
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      followerCount: json['followerCount'] ?? 0,
      totalPlays: json['totalPlays'] ?? 0,
      following: json['following'] ?? false,
      verified: json['verified'] as bool? ?? false,
    );
  }
}

