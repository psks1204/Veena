import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../../shared/models/dashboard_data.dart';
import '../../shared/models/media_item.dart';

enum DashboardState { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  
  DashboardState _state = DashboardState.initial;
  DashboardData? _data;
  String _errorMessage = '';

  // Pagination state for popular tracks
  List<MediaItem> _popularTracks = [];
  int _popularTracksPage = 0;
  final int _pageSize = 10;
  bool _isLoadingMore = false;
  bool _hasMoreTracks = true;

  DashboardState get state => _state;
  DashboardData? get data => _data;
  String get errorMessage => _errorMessage;

  List<MediaItem> get latestReleases => _data?.latestReleases ?? [];
  List<MediaItem> get popularTracks => _popularTracks;
  List<MediaItem> get recentlyPlayed => _data?.recentlyPlayed ?? [];

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreTracks => _hasMoreTracks;

  Future<void> loadDashboard({String? token}) async {
    _state = DashboardState.loading;
    _popularTracksPage = 0;
    _hasMoreTracks = true;
    notifyListeners();

    try {
      _data = await _dashboardService.getDashboardData(token: token);
      _popularTracks = List.from(_data?.popularTracks ?? []);
      _popularTracksPage = 1;
      _hasMoreTracks = _popularTracks.length >= _pageSize;
      _state = DashboardState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = DashboardState.error;
    }
    notifyListeners();
  }

  Future<void> loadMorePopularTracks({String? token}) async {
    if (_isLoadingMore || !_hasMoreTracks) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newTracks = await _dashboardService.getPopularTracks(
        token: token,
        page: _popularTracksPage,
        pageSize: _pageSize,
      );

      if (newTracks.isEmpty) {
        _hasMoreTracks = false;
      } else {
        _popularTracks.addAll(newTracks);
        _hasMoreTracks = newTracks.length >= _pageSize;
        _popularTracksPage++;
      }
    } catch (e) {
      // Silently fail for load more, user can scroll again
      debugPrint('Error loading more tracks: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
