import 'package:flutter/foundation.dart';
import '../models/media_item.dart';

/// Media Service
/// 
/// Provides media content - currently using mock data.
/// Replace with real API calls when backend is ready.
class MediaService extends ChangeNotifier {
  List<MediaItem> _latestReleases = [];
  List<MediaItem> _allMedia = [];
  bool _isLoading = false;
  String? _error;

  List<MediaItem> get latestReleases => _latestReleases;
  List<MediaItem> get allMedia => _allMedia;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all media content (using mock data)
  Future<PagedResponse<MediaItem>> fetchMedia({
    int page = 0,
    int size = 10,
    String? mediaType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Mock data from API response
      final mockItems = _getMockMediaItems();
      
      // Filter by media type if specified
      var filteredItems = mockItems;
      if (mediaType != null) {
        filteredItems = mockItems
            .where((item) => item.mediaType.value == mediaType)
            .toList();
      }

      _allMedia = filteredItems;
      _isLoading = false;
      notifyListeners();

      return PagedResponse<MediaItem>(
        content: filteredItems,
        totalPages: 1,
        totalElements: filteredItems.length,
        pageNumber: page,
        pageSize: size,
        isFirst: true,
        isLast: true,
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch latest releases
  Future<List<MediaItem>> fetchLatestReleases({int limit = 10}) async {
    final response = await fetchMedia(page: 0, size: limit);
    _latestReleases = response.content;
    notifyListeners();
    return _latestReleases;
  }

  /// Mock data from the user's provided API response
  List<MediaItem> _getMockMediaItems() {
    return [
      MediaItem(
        id: '9adf3515-a0e2-4806-acd3-af14cf42aad2',
        title: 'Test Song',
        description: 'Testing the songs',
        mediaType: MediaType.video,
        status: MediaStatus.ready,
        hlsUrl: 'https://d72o0611r6ack.cloudfront.net/media/9adf3515-a0e2-4806-acd3-af14cf42aad2/74aed4cf-b750-4b8e-aa35-14924cde7827-DGFlyर्/74aed4cf-b750-4b8e-aa35-14924cde7827-DGFlyर्.m3u8',
        thumbnailUrl: 'https://d7ouem6v1ji5j.cloudfront.net/media/9adf3515-a0e2-4806-acd3-af14cf42aad2/e2ab69d3-9d44-4bcd-b966-91cbd85ab930-6k logonew.png',
        lyricsUrl: 'https://d1msstr5h8ki3v.cloudfront.net/media/9adf3515-a0e2-4806-acd3-af14cf42aad2/de828f60-213a-432f-803b-cbe4af2a2070-ghumar.txt',
        createdAt: DateTime.parse('2026-01-23T14:43:37.522063Z'),
        updatedAt: DateTime.parse('2026-01-23T14:43:40.177893Z'),
      ),
      MediaItem(
        id: '98cb439b-a44c-4b87-8220-d3324f8fca12',
        title: 'Big Size Video',
        description: 'Big size video content',
        mediaType: MediaType.video,
        status: MediaStatus.ready,
        hlsUrl: 'https://d72o0611r6ack.cloudfront.net/media/98cb439b-a44c-4b87-8220-d3324f8fca12/b44a5c06-c5a5-4c66-8427-3b106fc59100-video1/b44a5c06-c5a5-4c66-8427-3b106fc59100-video1.m3u8',
        thumbnailUrl: 'https://d7ouem6v1ji5j.cloudfront.net/media/98cb439b-a44c-4b87-8220-d3324f8fca12/88bc3140-a024-45ef-985e-d48ff3c0f355-9e673d7a3353ac605fe3a9dd7e742168d36923e7.png',
        lyricsUrl: 'https://d1msstr5h8ki3v.cloudfront.net/media/98cb439b-a44c-4b87-8220-d3324f8fca12/507818f9-fe38-4b76-912a-7a4ab3600c88-ghumar.txt',
        createdAt: DateTime.parse('2026-01-23T14:45:14.733783Z'),
        updatedAt: DateTime.parse('2026-01-23T14:45:16.499332Z'),
      ),
      MediaItem(
        id: '103a8ab1-4df3-40da-9e95-460fac6bed42',
        title: 'Sample Title',
        description: 'Sample description',
        mediaType: MediaType.video,
        status: MediaStatus.ready,
        hlsUrl: 'https://d72o0611r6ack.cloudfront.net/media/103a8ab1-4df3-40da-9e95-460fac6bed42/d597dd44-4d18-4c47-9d80-f8dce21260be-video1/d597dd44-4d18-4c47-9d80-f8dce21260be-video1.m3u8',
        thumbnailUrl: 'https://d7ouem6v1ji5j.cloudfront.net/media/103a8ab1-4df3-40da-9e95-460fac6bed42/36c23228-a178-4b5f-b05e-bf1df90a229b-33cc70cdc0c619d51b9c332c80dc87bf03bb9db6.jpg',
        lyricsUrl: 'https://d1msstr5h8ki3v.cloudfront.net/media/103a8ab1-4df3-40da-9e95-460fac6bed42/5414879a-9b51-4df0-aa00-51450abe0b3c-ghumar.txt',
        createdAt: DateTime.parse('2026-01-23T14:58:02.174834Z'),
        updatedAt: DateTime.parse('2026-01-23T14:59:03.026118Z'),
      ),
      MediaItem(
        id: 'd6745d29-32e8-4fa3-885d-18815231c2d5',
        title: 'New Video',
        description: 'Description testing',
        mediaType: MediaType.video,
        status: MediaStatus.ready,
        hlsUrl: 'https://d72o0611r6ack.cloudfront.net/media/d6745d29-32e8-4fa3-885d-18815231c2d5/61cd51c9-8778-49f8-9f6a-2bbbed96d638-20231216_123255/61cd51c9-8778-49f8-9f6a-2bbbed96d638-20231216_123255.m3u8',
        thumbnailUrl: null,
        lyricsUrl: null,
        createdAt: DateTime.parse('2026-01-23T16:07:49.375950Z'),
        updatedAt: DateTime.parse('2026-01-23T16:08:04.383015Z'),
      ),
    ];
  }
}

