import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/media_item.dart';

/// Album Summary - for list views
class AlbumSummary {
  final int id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final int trackCount;

  const AlbumSummary({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.trackCount = 0,
  });

  factory AlbumSummary.fromJson(Map<String, dynamic> json) {
    return AlbumSummary(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'Untitled Album',
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      trackCount: json['trackCount'] as int? ?? 0,
    );
  }
}

/// Album Detail - includes tracks
class AlbumDetail extends AlbumSummary {
  final DateTime? createdAt;
  final List<MediaItem> tracks;

  AlbumDetail({
    required super.id,
    required super.name,
    super.description,
    super.coverImageUrl,
    super.trackCount,
    this.createdAt,
    required this.tracks,
  });

  factory AlbumDetail.fromJson(Map<String, dynamic> json) {
    final tracksList = json['tracks'] as List? ?? [];
    return AlbumDetail(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'Untitled Album',
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      trackCount: json['trackCount'] as int? ?? tracksList.length,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'] as String) 
          : null,
      tracks: tracksList
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
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
  
  /// GET /api/albums - Get all active albums
  Future<List<AlbumSummary>> getAllAlbums() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _api.get('/albums');
      if (data != null && data is List) {
        _albums = data.map((item) => AlbumSummary.fromJson(item)).toList();
      }
      _isLoading = false;
      notifyListeners();
      return _albums;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Get all albums error: $e');
      return [];
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
  
  /// Clear current album
  void clearCurrentAlbum() {
    _currentAlbum = null;
    notifyListeners();
  }
}
