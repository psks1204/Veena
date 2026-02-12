class Artist {
  final String id;
  final String name;
  final String? imageUrl;
  final String? genre;
  final int followerCount;
  final bool following;
  final bool verified;
  
  Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.genre,
    this.followerCount = 0,
    this.following = false,
    this.verified = false,
  });
  
  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: (json['id'] ?? json['artistId'] ?? '').toString(),
      name: json['name'] ?? json['artistName'] ?? 'Unknown Artist',
      imageUrl: json['imageUrl'] ?? json['artistImageUrl'] ?? json['thumbnailUrl'],
      genre: json['genre'] as String?,
      followerCount: json['followerCount'] ?? 0,
      following: json['following'] ?? false,
      verified: json['verified'] as bool? ?? false,
    );
  }
}
