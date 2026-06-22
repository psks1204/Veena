import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/media_item.dart';

/// Album Summary - for list views
/// Matches GET /api/albums response
class AlbumSummary {
  final String id;  // API returns string ID
  final String title;
  final String artistName;
  final String? coverUrl;
  final int trackCount;

  const AlbumSummary({
    required this.id,
    required this.title,
    required this.artistName,
    this.coverUrl,
    this.trackCount = 0,
  });

  factory AlbumSummary.fromJson(Map<String, dynamic> json) {
    // Extract artist name: prefer nested artist object, fall back to artistName
    String name = 'Unknown Artist';
    if (json['artist'] != null && json['artist'] is Map) {
      name = json['artist']['name'] as String? ?? 'Unknown Artist';
    } else {
      name = json['artistName'] as String? ?? 
             json['artist'] as String? ?? 
             'Unknown Artist';
    }

    return AlbumSummary(
      id: json['id']?.toString() ?? '0',
      title: json['name'] as String? ?? json['title'] as String? ?? 'Untitled Album',
      artistName: name,
      coverUrl: json['coverImageUrl'] as String? ?? json['coverUrl'] as String?,
      trackCount: json['trackCount'] as int? ?? 0,
    );
  }
}

/// Album Detail - includes tracks
/// Matches GET /api/albums/{id} response
class AlbumDetail {
  final int id; // Detail endpoint returns int ID
  final String name;
  final String artistName;
  final String? description;
  final String? coverImageUrl;
  final int trackCount;
  final DateTime? createdAt;
  final List<MediaItem> tracks;
  final double? averageRating;
  final int? ratingCount;
  final int? userRating;
  final String? userComment;
  final bool authenticated;

  const AlbumDetail({
    required this.id,
    required this.name,
    required this.artistName,
    this.description,
    this.coverImageUrl,
    this.trackCount = 0,
    this.createdAt,
    required this.tracks,
    this.averageRating,
    this.ratingCount,
    this.userRating,
    this.userComment,
    this.authenticated = false,
  });

  String? get releaseDate => createdAt != null ? "${createdAt!.year}" : null;

  AlbumDetail copyWith({
    double? averageRating,
    int? ratingCount,
    int? userRating,
    String? userComment,
    bool? authenticated,
  }) {
    return AlbumDetail(
      id: id,
      name: name,
      artistName: artistName,
      description: description,
      coverImageUrl: coverImageUrl,
      trackCount: trackCount,
      createdAt: createdAt,
      tracks: tracks,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      userRating: userRating ?? this.userRating,
      userComment: userComment ?? this.userComment,
      authenticated: authenticated ?? this.authenticated,
    );
  }

  factory AlbumDetail.fromJson(Map<String, dynamic> json) {
    final tracksList = json['tracks'] as List? ?? [];

    // Extract artist name: prefer nested artist object, fall back to artistName
    String name = 'Unknown Artist';
    if (json['artist'] != null && json['artist'] is Map) {
      name = json['artist']['name'] as String? ?? 'Unknown Artist';
    } else {
      name = json['artistName'] as String? ?? 
             json['artist'] as String? ?? 
             'Unknown Artist';
    }

    return AlbumDetail(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name:
          json['name'] as String? ?? json['title'] as String? ?? 'Untitled Album',
      artistName: name,
      description: json['description'] as String?,
      coverImageUrl:
          json['coverImageUrl'] as String? ?? json['coverUrl'] as String?,
      trackCount: json['trackCount'] as int? ?? tracksList.length,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      tracks: tracksList
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageRating: json['averageRating'] != null
          ? (json['averageRating'] as num).toDouble()
          : null,
      ratingCount: json['ratingCount'] != null
          ? (json['ratingCount'] as num).toInt()
          : null,
      userRating: json['userRating'] as int?,
      userComment: json['userComment'] as String?,
      authenticated: json['authenticated'] as bool? ?? false,
    );
  }
}

/// Rating response from the rating endpoints
class AlbumRatingResponse {
  final double? averageRating;
  final int? ratingCount;
  final int? userRating;
  final String? userComment;

  const AlbumRatingResponse({
    this.averageRating,
    this.ratingCount,
    this.userRating,
    this.userComment,
  });

  factory AlbumRatingResponse.fromJson(Map<String, dynamic> json) {
    return AlbumRatingResponse(
      averageRating: json['averageRating'] != null
          ? (json['averageRating'] as num).toDouble()
          : null,
      ratingCount: json['ratingCount'] != null
          ? (json['ratingCount'] as num).toInt()
          : null,
      userRating: json['userRating'] as int?,
      userComment: json['userComment'] as String?,
    );
  }
}

/// Review item response for reviews list
class AlbumReviewResponse {
  final String userName;
  final String? userPhotoUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const AlbumReviewResponse({
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory AlbumReviewResponse.fromJson(Map<String, dynamic> json) {
    return AlbumReviewResponse(
      userName: json['userName'] as String? ?? 'Anonymous',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Album Service
/// 
/// Handles album-specific API operations.
class AlbumService extends ChangeNotifier {
  final ApiService _api;
  
  AlbumService(this._api);
  
  List<AlbumSummary> _albums = [];
  AlbumDetail? _currentAlbum;
  bool _isLoading = false;
  String? _error;
  
  List<AlbumSummary> get albums => _albums;
  AlbumDetail? get currentAlbum => _currentAlbum;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// GET /api/albums - Get albums (paginated)
  Future<PagedResponse<AlbumSummary>> getAllAlbums({int page = 0, int size = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };
      
      final data = await _api.get('/albums', queryParams: queryParams);
      if (data != null) {
        final response = PagedResponse<AlbumSummary>.fromJson(
          data,
          (item) => AlbumSummary.fromJson(item),
        );
        _albums = response.content;
        _isLoading = false;
        notifyListeners();
        return response;
      }
      
      _isLoading = false;
      notifyListeners();
      return PagedResponse<AlbumSummary>(
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
      debugPrint('Get albums error: $e');
      return PagedResponse<AlbumSummary>(
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
  
  /// GET /api/albums/search - Search albums by name
  Future<PagedResponse<AlbumSummary>> searchAlbums(
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
      
      final data = await _api.get('/albums/search', queryParams: queryParams);
      
      if (data != null && data['content'] != null) {
        return PagedResponse.fromJson(
          data,
          (item) => AlbumSummary.fromJson(item),
        );
      }
      
      return PagedResponse<AlbumSummary>(
        content: [],
        totalPages: 0,
        totalElements: 0,
        pageNumber: page,
        pageSize: size,
        isFirst: true,
        isLast: true,
      );
    } catch (e) {
      debugPrint('Search albums error: $e');
      return PagedResponse<AlbumSummary>(
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
  
  /// GET /api/albums/{id} - Get album details with tracks
  Future<AlbumDetail?> getAlbumDetails(int albumId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _api.get('/albums/$albumId');
      
      if (data != null) {
        _currentAlbum = AlbumDetail.fromJson(data);
        debugPrint('[AlbumService] Loaded album: ${_currentAlbum?.name} with ${_currentAlbum?.tracks.length} tracks');
        _isLoading = false;
        notifyListeners();
        return _currentAlbum;
      }
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Get album details error: $e');
      return null;
    }
  }

  /// POST /api/albums/{id}/rate - Rate an album
  Future<AlbumRatingResponse?> rateAlbum(
    int albumId,
    int rating,
    String? comment,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      };

      final data = await _api.post('/albums/$albumId/rate', body: body);
      if (data != null) {
        final ratingResponse = AlbumRatingResponse.fromJson(data);
        
        // Update current album cache if matches
        if (_currentAlbum != null && _currentAlbum!.id == albumId) {
          _currentAlbum = _currentAlbum!.copyWith(
            averageRating: ratingResponse.averageRating,
            ratingCount: ratingResponse.ratingCount,
            userRating: ratingResponse.userRating,
            userComment: ratingResponse.userComment,
          );
        }
        
        _isLoading = false;
        notifyListeners();
        return ratingResponse;
      }
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Rate album error: $e');
      rethrow;
    }
  }

  /// GET /api/albums/{id}/rating - Get album rating status
  Future<AlbumRatingResponse?> getAlbumRating(int albumId) async {
    try {
      final data = await _api.get('/albums/$albumId/rating');
      if (data != null) {
        final ratingResponse = AlbumRatingResponse.fromJson(data);
        
        // Update current album cache if matches
        if (_currentAlbum != null && _currentAlbum!.id == albumId) {
          _currentAlbum = _currentAlbum!.copyWith(
            averageRating: ratingResponse.averageRating,
            ratingCount: ratingResponse.ratingCount,
            userRating: ratingResponse.userRating,
            userComment: ratingResponse.userComment,
          );
          notifyListeners();
        }
        return ratingResponse;
      }
      return null;
    } catch (e) {
      debugPrint('Get album rating error: $e');
      return null;
    }
  }

  /// DELETE /api/albums/{id}/rating - Delete user rating
  Future<void> deleteRating(int albumId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete('/albums/$albumId/rating');
      
      // Fetch updated rating info to refresh cache
      await getAlbumRating(albumId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Delete rating error: $e');
      rethrow;
    }
  }

  /// GET /api/albums/{id}/reviews - Get reviews (paginated)
  Future<PagedResponse<AlbumReviewResponse>> getAlbumReviews(
    int albumId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };
      
      final data = await _api.get('/albums/$albumId/reviews', queryParams: queryParams);
      if (data != null) {
        return PagedResponse<AlbumReviewResponse>.fromJson(
          data,
          (item) => AlbumReviewResponse.fromJson(item),
        );
      }
      
      return PagedResponse<AlbumReviewResponse>(
        content: [],
        totalPages: 0,
        totalElements: 0,
        pageNumber: page,
        pageSize: size,
        isFirst: true,
        isLast: true,
      );
    } catch (e) {
      debugPrint('Get album reviews error: $e');
      return PagedResponse<AlbumReviewResponse>(
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
  
  /// Clear current album
  void clearCurrentAlbum() {
    _currentAlbum = null;
    notifyListeners();
  }
}
