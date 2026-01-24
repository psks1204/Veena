import 'media_item.dart';

class DashboardData {
  final List<MediaItem> latestReleases;
  final List<MediaItem> popularTracks;
  final List<MediaItem> recentlyPlayed;
  final List<dynamic> recommendedArtists;

  DashboardData({
    required this.latestReleases,
    required this.popularTracks,
    required this.recentlyPlayed,
    required this.recommendedArtists,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      latestReleases: (json['latestReleases'] as List)
          .map((i) => MediaItem.fromJson(i))
          .toList(),
      popularTracks: (json['popularTracks'] as List)
          .map((i) => MediaItem.fromJson(i))
          .toList(),
      recentlyPlayed: (json['recentlyPlayed'] as List)
          .map((i) => MediaItem.fromJson(i))
          .toList(),
      recommendedArtists: json['recommendedArtists'] ?? [],
    );
  }
}
