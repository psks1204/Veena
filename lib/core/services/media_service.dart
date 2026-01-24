import 'api_service.dart';
import '../../shared/models/media_item.dart';

class MediaService {
  final ApiService _apiService = ApiService();

  /// Toggle like status for a media item
  Future<LikeResponse> toggleLike(String mediaId, {String? token}) async {
    try {
      final response = await _apiService.post(
        '/media/$mediaId/like',
        token: token,
      );
      return LikeResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get like status for a media item
  Future<LikeResponse> getLikeStatus(String mediaId, {String? token}) async {
    try {
      final response = await _apiService.get(
        '/media/$mediaId/like',
        token: token,
      );
      return LikeResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all liked media for the current user
  Future<List<MediaItem>> getLikedMedia({String? token}) async {
    try {
      final List response = await _apiService.get(
        '/media/liked',
        token: token,
      );
      return response.map((item) => MediaItem.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch lyrics content from URL
  Future<String?> fetchLyrics(String lyricsUrl) async {
    try {
      final response = await _apiService.getRaw(lyricsUrl);
      return response;
    } catch (e) {
      return null;
    }
  }
}

class LikeResponse {
  final bool liked;
  final int likeCount;

  LikeResponse({
    required this.liked,
    required this.likeCount,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      liked: json['liked'] ?? false,
      likeCount: json['likeCount'] ?? 0,
    );
  }
}
