import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/media_item.dart';
import '../models/artist.dart';

/// Dashboard Service
/// 
/// Fetches home screen content from the backend.
class DashboardService extends ChangeNotifier {
  final ApiService _api;
  
  DashboardService(this._api);
  
  List<MediaItem> _latestReleases = [];
  List<MediaItem> _popularTracks = [];
  List<MediaItem> _recentlyPlayed = [];
  List<MediaItem> _videos = [];
  List<MediaItem> _audios = [];
  bool _isLoading = false;
  String? _error;
  
  List<MediaItem> get latestReleases => _latestReleases;
  List<MediaItem> get popularTracks => _popularTracks;
  List<MediaItem> get recentlyPlayed => _recentlyPlayed;
  List<MediaItem> get videos => _videos;
  List<MediaItem> get audios => _audios;
  List<Artist> _artists = [];
  List<Artist> get artists => _artists;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Fetch all dashboard data
  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _api.get('/user/dashboard');
      
      // Parse dashboard sections
      if (data != null) {
        if (data['latestReleases'] != null) {
          _latestReleases = (data['latestReleases'] as List)
              .map((item) => MediaItem.fromJson(item))
              .toList();
        }
        if (data['popularTracks'] != null) {
          _popularTracks = (data['popularTracks'] as List)
              .map((item) => MediaItem.fromJson(item))
              .toList();
        }
        if (data['recentlyPlayed'] != null) {
          final allHistory = (data['recentlyPlayed'] as List)
              .map((item) => MediaItem.fromJson(item))
              .toList();
          
          final seen = <String>{};
          _recentlyPlayed = allHistory.where((item) => seen.add(item.id)).toList();
        }
      }

      // Fetch artists, videos, and audios concurrently
      await Future.wait([
        // Artists
        (() async {
          try {
            final artistsData = await _api.get('/user/library/artists/all');
            if (artistsData != null && artistsData is List) {
              _artists = artistsData.map((item) => Artist.fromJson(item)).toList();
            }
          } catch (e) {
            debugPrint('Dashboard artists fetch error: $e');
          }
        })(),
        // Videos (dedicated fetch via /media?type=VIDEO)
        (() async {
          try {
            final videoData = await _api.get('/media', queryParams: {
              'type': 'VIDEO',
              'page': '0',
              'size': '20',
            });
            if (videoData != null && videoData['content'] != null) {
              _videos = (videoData['content'] as List)
                  .map((item) => MediaItem.fromJson(item))
                  .toList();
            }
          } catch (e) {
            debugPrint('Dashboard videos fetch error: $e');
          }
        })(),
        // Audios (dedicated fetch via /media?type=AUDIO)
        (() async {
          try {
            final audioData = await _api.get('/media', queryParams: {
              'type': 'AUDIO',
              'page': '0',
              'size': '20',
            });
            if (audioData != null && audioData['content'] != null) {
              _audios = (audioData['content'] as List)
                  .map((item) => MediaItem.fromJson(item))
                  .toList();
            }
          } catch (e) {
            debugPrint('Dashboard audios fetch error: $e');
          }
        })(),
      ]);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Dashboard fetch error: $e');
    }
  }
  
  /// Fetch latest releases only
  Future<List<MediaItem>> fetchLatestReleases() async {
    try {
      final data = await _api.get('/user/dashboard/latest');
      if (data != null && data is List) {
        _latestReleases = data.map((item) => MediaItem.fromJson(item)).toList();
        notifyListeners();
      }
      return _latestReleases;
    } catch (e) {
      debugPrint('Latest releases error: $e');
      return [];
    }
  }
  
  /// Fetch popular/trending tracks
  Future<List<MediaItem>> fetchPopularTracks() async {
    try {
      final data = await _api.get('/user/dashboard/popular');
      if (data != null && data is List) {
        _popularTracks = data.map((item) => MediaItem.fromJson(item)).toList();
        notifyListeners();
      }
      return _popularTracks;
    } catch (e) {
      debugPrint('Popular tracks error: $e');
      return [];
    }
  }
  
  /// Fetch user's recently played
  Future<List<MediaItem>> fetchRecentlyPlayed() async {
    try {
      final data = await _api.get('/user/dashboard/history');
      if (data != null && data is List) {
        final allItems = data.map((item) => MediaItem.fromJson(item)).toList();
        // Deduplicate
        final seen = <String>{};
        _recentlyPlayed = allItems.where((item) => seen.add(item.id)).toList();
        notifyListeners();
      }
      return _recentlyPlayed;
    } catch (e) {
      debugPrint('Recently played error: $e');
      return [];
    }
  }
  /// Fetch paginated latest releases with optional type filter
  Future<List<MediaItem>> fetchLatestMedia({
    int page = 1, 
    int limit = 20, 
    String? type,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      };
      
      final data = await _api.get('/user/dashboard/latest', queryParams: queryParams);
      
      if (data != null && data is List) {
        return data.map((item) => MediaItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Latest media fetch error: $e');
      return [];
    }
  }

  /// Fetch paginated popular tracks with optional type filter
  Future<List<MediaItem>> fetchPopularMedia({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      };

      final data = await _api.get('/user/dashboard/popular', queryParams: queryParams);

      if (data != null && data is List) {
        return data.map((item) => MediaItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Popular media fetch error: $e');
      return [];
    }
  }
}
