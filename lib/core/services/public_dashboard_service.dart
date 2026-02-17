import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'api_service.dart';

/// Public Dashboard Service
///
/// Fetches dashboard content from the public API (no auth required).
/// Returns the same data shape as DashboardService but without
/// playable media URLs (streamUrl/videoUrl will be null).
class PublicDashboardService extends ChangeNotifier {
  List<MediaItem> _latestReleases = [];
  List<MediaItem> _popularTracks = [];
  bool _isLoading = false;
  String? _error;

  List<MediaItem> get latestReleases => _latestReleases;
  List<MediaItem> get popularTracks => _popularTracks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch public dashboard data (no auth token)
  Future<void> fetchPublicDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/user/dashboard');
      debugPrint('🌐 PUBLIC GET: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📥 Public Dashboard Status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

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
        }
      } else {
        _error = 'Failed to load content (${response.statusCode})';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Public dashboard fetch error: $e');
    }
  }
}
