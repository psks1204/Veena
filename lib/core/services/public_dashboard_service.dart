import 'dart:async';

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
  List<MediaItem> _videos = [];
  List<MediaItem> _audios = [];
  List<MediaItem> _featuredActive = [];
  bool _isLoading = false;
  String? _error;

  List<MediaItem> get latestReleases => _latestReleases;
  List<MediaItem> get popularTracks => _popularTracks;
  List<MediaItem> get videos => _videos;
  List<MediaItem> get audios => _audios;
  List<MediaItem> get featuredActive => _featuredActive;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool _isLoadingSecondary = false;

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

      unawaited(_loadSecondarySections());
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Public dashboard fetch error: $e');
    }
  }

  Future<void> _loadSecondarySections() async {
    if (_isLoadingSecondary) return;
    _isLoadingSecondary = true;

    try {
      await Future.wait([
        (() async {
          try {
            final videoUri = Uri.parse('${ApiService.baseUrl}/media?type=VIDEO&page=0&size=20');
            final videoResp = await http.get(videoUri, headers: {'Content-Type': 'application/json'});
            if (videoResp.statusCode >= 200 && videoResp.statusCode < 300) {
              final videoData = jsonDecode(videoResp.body);
              if (videoData != null && videoData['content'] != null) {
                _videos = (videoData['content'] as List)
                    .map((item) => MediaItem.fromJson(item))
                    .toList();
              }
            }
          } catch (e) {
            debugPrint('Public videos fetch error: $e');
          }
        })(),
        (() async {
          try {
            final audioUri = Uri.parse('${ApiService.baseUrl}/media?type=AUDIO&page=0&size=20');
            final audioResp = await http.get(audioUri, headers: {'Content-Type': 'application/json'});
            if (audioResp.statusCode >= 200 && audioResp.statusCode < 300) {
              final audioData = jsonDecode(audioResp.body);
              if (audioData != null && audioData['content'] != null) {
                _audios = (audioData['content'] as List)
                    .map((item) => MediaItem.fromJson(item))
                    .toList();
              }
            }
          } catch (e) {
            debugPrint('Public audios fetch error: $e');
          }
        })(),
        (() async {
          try {
            debugPrint('🚀 [PublicDashboardService] Calling fetchFeaturedActive...');
            final featuredUri = Uri.parse('${ApiService.baseUrl}/featured/active');
            final featuredResp = await http.get(featuredUri, headers: {'Content-Type': 'application/json'});
            debugPrint('🚀 [PublicDashboardService] fetchFeaturedActive status: ${featuredResp.statusCode}');
            if (featuredResp.statusCode >= 200 && featuredResp.statusCode < 300) {
              final featuredData = jsonDecode(featuredResp.body);
              if (featuredData != null && featuredData is List) {
                _featuredActive = featuredData.map((item) {
                  return MediaItem(
                    id: item['mediaId'] as String? ?? 'unknown_id',
                    title: item['mediaTitle'] as String? ?? 'Featured Item',
                    mediaType: MediaType.fromString(item['mediaType'] as String? ?? 'AUDIO'),
                    thumbnailUrl: item['thumbnailUrl'] as String?,
                    hlsUrl: item['hlsUrl'] as String?,
                    status: MediaStatus.published,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    artist: item['artist'] != null
                        ? ArtistInfo.fromJson(item['artist'] as Map<String, dynamic>)
                        : null,
                  );
                }).toList();
                debugPrint('🚀 [PublicDashboardService] Parsed ${_featuredActive.length} items');
              }
            }
          } catch (e) {
            debugPrint('❌ [PublicDashboardService] Featured active error: $e');
          }
        })(),
      ]);
    } finally {
      _isLoadingSecondary = false;
      notifyListeners();
    }
  }
}
