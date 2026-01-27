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
  Map<String, int> _likeCounts = {};
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  
  // Pagination state for search
  int _searchPage = 0;
  int _searchTotalPages = 0;
  bool _hasMoreSearchResults = false;
  
  List<MediaItem> get searchResults => _searchResults;
  List<MediaItem> get allMedia => _allMedia;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  bool get hasMoreSearchResults => _hasMoreSearchResults;
  
  /// Check if a media item is liked
  bool isLiked(String mediaId) => _likedMediaIds.contains(mediaId);
  
  /// Get like count for a media item
  int getLikeCount(String mediaId) => _likeCounts[mediaId] ?? 0;
  
  // ==================== SEARCH ====================
  
  /// Search for tracks, artists, or albums
  Future<List<MediaItem>> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _hasMoreSearchResults = false;
      notifyListeners();
      return [];
    }
    
    _isSearching = true;
    _searchPage = 0;
    notifyListeners();
    
    try {
      final data = await _api.get('/media/search', queryParams: {
        'query': query,
        'page': '0',
        'size': '20',
      });
      
      // Handle paginated response (API returns Page<MediaResponse>)
      if (data != null && data['content'] != null) {
        _searchResults = (data['content'] as List)
            .map((item) => MediaItem.fromJson(item))
            .toList();
        _searchTotalPages = data['totalPages'] as int? ?? 1;
        _hasMoreSearchResults = !(data['last'] as bool? ?? true);
      } else if (data != null && data is List) {
        // Fallback for direct list response
        _searchResults = data.map((item) => MediaItem.fromJson(item)).toList();
        _hasMoreSearchResults = false;
      } else {
        _searchResults = [];
        _hasMoreSearchResults = false;
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
  
  /// Search with pagination - returns full paged response
  Future<PagedResponse<MediaItem>> searchPaginated(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = {
        if (query.isNotEmpty) 'query': query,
        'page': page.toString(),
        'size': size.toString(),
      };
      
      final data = await _api.get('/media/search', queryParams: queryParams);
      
      if (data != null && data['content'] != null) {
        return PagedResponse.fromJson(
          data,
          (item) => MediaItem.fromJson(item),
        );
      }
      
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
      debugPrint('Search paginated error: $e');
      return PagedResponse<MediaItem>(
        content: [],
        totalPages: 0,
        totalElements: 0,
        pageNumber: page,
        pageSize: size,
        isFirst: true,
        isLast: true,
      );
    }
  }
  
  /// Load more search results (append to existing)
  Future<List<MediaItem>> loadMoreSearchResults(String query) async {
    if (!_hasMoreSearchResults || _isSearching) {
      return _searchResults;
    }
    
    _isSearching = true;
    _searchPage++;
    notifyListeners();
    
    try {
      final data = await _api.get('/media/search', queryParams: {
        'query': query,
        'page': _searchPage.toString(),
        'size': '20',
      });
      
      if (data != null && data['content'] != null) {
        final newItems = (data['content'] as List)
            .map((item) => MediaItem.fromJson(item))
            .toList();
        _searchResults.addAll(newItems);
        _hasMoreSearchResults = !(data['last'] as bool? ?? true);
      }
      
      _isSearching = false;
      notifyListeners();
      return _searchResults;
    } catch (e) {
      _isSearching = false;
      _searchPage--; // Revert page on error
      notifyListeners();
      debugPrint('Load more search error: $e');
      return _searchResults;
    }
  }
  
  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _searchPage = 0;
    _hasMoreSearchResults = false;
    notifyListeners();
  }
  
  // ==================== LIKE / FAVORITE ====================
  
  /// Toggle like status for a media item - returns LikeResponse
  Future<LikeResponse?> toggleLike(String mediaId) async {
    try {
      final data = await _api.post('/media/$mediaId/like');
      
      if (data != null) {
        final response = LikeResponse.fromJson(data);
        
        if (response.liked) {
          _likedMediaIds.add(mediaId);
        } else {
          _likedMediaIds.remove(mediaId);
        }
        _likeCounts[mediaId] = response.likeCount;
        
        notifyListeners();
        return response;
      }
      
      // Fallback if no response body - toggle locally
      if (_likedMediaIds.contains(mediaId)) {
        _likedMediaIds.remove(mediaId);
      } else {
        _likedMediaIds.add(mediaId);
      }
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Toggle like error: $e');
      return null;
    }
  }
  
  /// Check if a media item is liked (from API)
  Future<LikeResponse?> checkLikeStatus(String mediaId) async {
    try {
      final data = await _api.get('/media/$mediaId/like');
      
      if (data != null) {
        final response = LikeResponse.fromJson(data);
        
        if (response.liked) {
          _likedMediaIds.add(mediaId);
        } else {
          _likedMediaIds.remove(mediaId);
        }
        _likeCounts[mediaId] = response.likeCount;
        
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Check like status error: $e');
      return null;
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
  
  /// Initialize liked media IDs from a list (for bulk loading)
  void setLikedMediaIds(Set<String> ids) {
    _likedMediaIds = ids;
    notifyListeners();
  }
  
  // ==================== PLAYBACK TRACKING ====================
  
  /// Record play event for analytics
  Future<void> recordPlay(String mediaId, {Duration? position}) async {
    try {
      final body = position != null ? {'position': position.inSeconds} : null;
      await _api.post('/media/$mediaId/play', body: body);
      debugPrint('📊 Recorded play for media: $mediaId');
    } catch (e) {
      debugPrint('Record play error: $e');
    }
  }
  
  // ==================== FETCH MEDIA ====================
  
  /// Fetch all media (paginated)
  Future<PagedResponse<MediaItem>> fetchMedia({
    int page = 0,
    int size = 20,
    String? mediaType,
    String? sort,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        if (mediaType != null) 'mediaType': mediaType,
        if (sort != null) 'sort': sort,
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
