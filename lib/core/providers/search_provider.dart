import 'package:flutter/foundation.dart';
import '../services/search_service.dart';
import '../../features/auth/services/auth_service.dart';
import '../../shared/models/media_item.dart';

enum SearchState { initial, loading, success, error }

class SearchProvider extends ChangeNotifier {
  final SearchService _searchService = SearchService();
  AuthService? _authService;

  SearchState _state = SearchState.initial;
  List<MediaItem> _results = [];
  String _errorMessage = '';

  SearchState get state => _state;
  List<MediaItem> get results => _results;
  String get errorMessage => _errorMessage;

  void updateAuth(AuthService auth) {
    _authService = auth;
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _results = [];
      _state = SearchState.initial;
      notifyListeners();
      return;
    }

    _state = SearchState.loading;
    notifyListeners();

    try {
      _results = await _searchService.searchMedia(
        query,
        token: _authService?.token,
      );
      _state = SearchState.success;
    } catch (e) {
      _state = SearchState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
