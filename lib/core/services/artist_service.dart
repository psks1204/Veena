import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/artist.dart';
import '../models/media_item.dart';

class ArtistService extends ChangeNotifier {
  final ApiService _api;

  ArtistService(this._api);

  bool _isLoading = false;
  
  bool get isLoading => _isLoading;

  /// Toggle follow status for an artist
  /// POST /api/artists/{artistId}/toggle-follow
  Future<Artist?> toggleFollow(String artistId) async {
    try {
      final data = await _api.post('/artists/$artistId/toggle-follow', body: {});
      if (data != null) {
        return Artist.fromJson(data);
      }
    } catch (e) {
      debugPrint('Toggle follow error: $e');
    }
    return null;
  }


  /// Get followed artists (paginated)
  /// GET /api/artists/following/page
  Future<PagedResponse<Artist>> getFollowedArtists({int page = 0, int size = 30}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };
      
      final data = await _api.get('/artists/following/page', queryParams: queryParams);
      
      if (data != null) {
        return PagedResponse.fromJson(data, (item) => Artist.fromJson(item));
      }
      return PagedResponse<Artist>(
        content: [],
        totalPages: 0,
        totalElements: 0,
        pageNumber: page,
        pageSize: size,
        isFirst: true,
        isLast: true,
      );
    } catch (e) {
      debugPrint('Get followed artists error: $e');
      return PagedResponse<Artist>(
        content: [],
        totalPages: 0,
        totalElements: 0,
        pageNumber: page,
        pageSize: size,
        isFirst: true,
        isLast: true,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get all artists (for dashboard/discovery)
  /// GET /api/user/library/artists
  Future<PagedResponse<Artist>> getAllArtists({int page = 0, int size = 30}) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };
      final data = await _api.get('/user/library/artists', queryParams: queryParams);
      if (data != null) {
        return PagedResponse.fromJson(data, (item) => Artist.fromJson(item));
      }
    } catch (e) {
      debugPrint('Get all artists error: $e');
    }
    return PagedResponse<Artist>(
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
