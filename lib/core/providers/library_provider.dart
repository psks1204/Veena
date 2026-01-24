import 'package:flutter/foundation.dart';
import '../services/dashboard_service.dart';
import '../../features/auth/services/auth_service.dart';
import '../../shared/models/media_item.dart';

enum LibraryState { initial, loading, success, error }

class LibraryProvider extends ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  AuthService? _authService;

  LibraryState _state = LibraryState.initial;
  List<MediaItem> _history = [];
  String _errorMessage = '';

  LibraryState get state => _state;
  List<MediaItem> get history => _history;
  String get errorMessage => _errorMessage;

  void updateAuth(AuthService auth) {
    _authService = auth;
  }

  Future<void> loadLibrary() async {
    _state = LibraryState.loading;
    notifyListeners();

    try {
      _history = await _dashboardService.getRecentlyPlayed(
        token: _authService?.token,
      );
      _state = LibraryState.success;
    } catch (e) {
      _state = LibraryState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
