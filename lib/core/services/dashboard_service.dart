import 'api_service.dart';
import '../../shared/models/dashboard_data.dart';
import '../../shared/models/media_item.dart';

class DashboardService {
  final ApiService _apiService = ApiService();

  Future<DashboardData> getDashboardData({String? token}) async {
    final response = await _apiService.get('/user/dashboard', token: token);
    return DashboardData.fromJson(response);
  }

  Future<List<MediaItem>> getLatestReleases({String? token}) async {
    final List response = await _apiService.get('/user/dashboard/latest', token: token);
    return response.map((i) => MediaItem.fromJson(i)).toList();
  }

  Future<List<MediaItem>> getPopularTracks({String? token, int page = 0, int pageSize = 10}) async {
    final List response = await _apiService.get(
      '/user/dashboard/popular?page=$page&size=$pageSize',
      token: token,
    );
    return response.map((i) => MediaItem.fromJson(i)).toList();
  }

  Future<List<MediaItem>> getRecentlyPlayed({String? token}) async {
    final List response = await _apiService.get('/user/dashboard/history', token: token);
    return response.map((i) => MediaItem.fromJson(i)).toList();
  }
}
