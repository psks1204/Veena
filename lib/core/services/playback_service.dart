import 'api_service.dart';

class PlaybackService {
  final ApiService _apiService = ApiService();

  Future<void> recordPlay(String mediaId, {int? position, String? token}) async {
    try {
      await _apiService.post(
        '/media/$mediaId/play',
        body: position != null ? {'position': position} : {},
        token: token,
      );
    } catch (e) {
      // Log error but don't fail playback
      print('Error recording play: $e');
    }
  }
}
