import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/media_item.dart';

/// Media Service
/// 
/// Handles media operations: search, like/unlike, playback tracking.
class MediaService extends ChangeNotifier {
  final ApiService _api;
  
  MediaService(this._api);
  
  List<MediaItem> _searchResults = [];
  List<MediaItem> _allMedia = [];
  Set<String> _likedMediaIds = {};
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  
  List<MediaItem> get searchResults => _searchResults;
  List<MediaItem> get allMedia => _allMedia;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  
  /// Check if a media item is liked
  bool isLiked(String mediaId) => _likedMediaIds.contains(mediaId);
  
  // ==================== SEARCH ====================
  
  /// Search for tracks, artists, or albums
  Future<List<MediaItem>> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return [];
    }
    
    _isSearching = true;
    notifyListeners();
    
    try {
      final data = await _api.get('/media/search', queryParams: {'query': query});
      
      if (data != null && data is List) {
        _searchResults = data.map((item) => MediaItem.fromJson(item)).toList();
      } else if (data != null && data['results'] != null) {
        _searchResults = (data['results'] as List)
            .map((item) => MediaItem.fromJson(item))
            .toList();
      } else {
        _searchResults = [];
      }
      
      _isSearching = false;
      notifyListeners();
      return _searchResults;
    } catch (e) {
      _isSearching = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Search error: $e');
      return [];
    }
  }
  
  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
  
  // ==================== LIKE / FAVORITE ====================
  
  /// Toggle like status for a media item
  Future<bool> toggleLike(String mediaId) async {
    try {
      await _api.post('/media/$mediaId/like');
      
      if (_likedMediaIds.contains(mediaId)) {
        _likedMediaIds.remove(mediaId);
      } else {
        _likedMediaIds.add(mediaId);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Toggle like error: $e');
      return false;
    }
  }
  
  /// Check if a media item is liked (from API)
  Future<bool> checkLikeStatus(String mediaId) async {
    try {
      final data = await _api.get('/media/$mediaId/like');
      final isLiked = data?['liked'] ?? false;
      
      if (isLiked) {
        _likedMediaIds.add(mediaId);
      } else {
        _likedMediaIds.remove(mediaId);
      }
      
      return isLiked;
    } catch (e) {
      debugPrint('Check like status error: $e');
      return false;
    }
  }
  
  /// Get all liked media
  Future<List<MediaItem>> getLikedMedia() async {
    try {
      final data = await _api.get('/media/liked');
      if (data != null && data is List) {
        final liked = data.map((item) => MediaItem.fromJson(item)).toList();
        _likedMediaIds = liked.map((m) => m.id).toSet();
        notifyListeners();
        return liked;
      }
    } catch (e) {
      debugPrint('Get liked media error: $e');
    }
    return [];
  }
  
  // ==================== PLAYBACK TRACKING ====================
  
  /// Record play event for analytics
  Future<void> recordPlay(String mediaId, {Duration? position}) async {
    try {
      await _api.post('/media/$mediaId/play', body: {
        if (position != null) 'position': position.inSeconds,
      });
    } catch (e) {
      debugPrint('Record play error: $e');
    }
  }
  
  // ==================== LYRICS ====================
  
  /// Fetch lyrics from external URL
  Future<String?> fetchLyrics(String lyricsUrl) async {
    try {
      final response = await Uri.parse(lyricsUrl).toString();
      // Direct fetch from lyrics URL (not going through our API)
      final result = await _api.get(lyricsUrl);
      return result?.toString();
    } catch (e) {
      debugPrint('Fetch lyrics error: $e');
      return null;
    }
  }
  
  // ==================== FETCH MEDIA ====================
  
  /// Fetch all media (paginated)
  Future<PagedResponse<MediaItem>> fetchMedia({
    int page = 0,
    int size = 20,
    String? mediaType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        if (mediaType != null) 'mediaType': mediaType,
      };
      
      final data = await _api.get('/media', queryParams: queryParams);
      
      if (data != null) {
        final response = PagedResponse<MediaItem>.fromJson(
          data,
          (item) => MediaItem.fromJson(item),
        );
        _allMedia = response.content;
        _isLoading = false;
        notifyListeners();
        return response;
      }
      
      _isLoading = false;
      notifyListeners();
      return PagedResponse<MediaItem>(
        content: [],
        totalPages: 0,
        totalElements: 0,
        pageNumber: page,
        pageSize: size,
        isFirst: true,
        isLast: true,
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
