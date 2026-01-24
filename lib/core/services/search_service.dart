import 'api_service.dart';
import '../../shared/models/media_item.dart';

class SearchService {
  final ApiService _apiService = ApiService();

  Future<List<MediaItem>> searchMedia(String query, {String? token}) async {
    if (query.isEmpty) return [];
    
    final response = await _apiService.get(
      '/media/search?query=${Uri.encodeComponent(query)}',
      token: token,
    );
    
    // Page response from Spring Boot contains content in 'content' field
    final List content = response['content'] ?? [];
    return content.map((i) => MediaItem.fromJson(i)).toList();
  }
}
