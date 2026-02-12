import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/artist.dart';

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
  Future<List<Artist>> getFollowedArtists({int page = 0, int size = 20}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
      };
      
      final data = await _api.get('/artists/following/page', queryParams: queryParams);
      
      if (data != null && data['content'] != null) {
        final content = data['content'] as List;
        return content.map((item) => Artist.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get followed artists error: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get all artists (for dashboard/discovery)
  /// GET /api/user/library/artists/all (Using the existing endpoint for now)
  Future<List<Artist>> getAllArtists() async {
    try {
      // Assuming we still want to show a general list of artists somewhere
      final data = await _api.get('/user/library/artists/all');
      if (data != null && data is List) {
        return data.map((item) => Artist.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get all artists error: $e');
      return [];
    }
  }
}
